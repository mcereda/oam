#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.12"
# dependencies = ["boto3>=1.43", "pyyaml", "rich"]
# ///

"""
List (and optionally delete or archive) images across one or many AWS ECR repositories.

Usage:
    - list:
        uv run cleanup-old-images.py <repository> [<repository>...]   # explicit list
        uv run cleanup-old-images.py --all                            # every repository in the registry
        uv run cleanup-old-images.py <repository> --output json
    - delete:
        uv run cleanup-old-images.py <repository> --delete                     # dry-run
        uv run cleanup-old-images.py <repository> -d --execute                 # effectively delete
        uv run cleanup-old-images.py <repository> -d --older-than 60
        uv run cleanup-old-images.py <repository> -d --keep-last 5             # always keep the 5 newest images
        uv run cleanup-old-images.py <repository> -d --exclude-tag latest --exclude-tag 'v*'
        uv run cleanup-old-images.py <repository> -d --exclude-digest sha256:abc12
        uv run cleanup-old-images.py <repository> -d --execute --force         # skip the consumer-check warning
        uv run cleanup-old-images.py <repository> -d --check-eks --show-kept   # also show images kept by the age gate
        uv run cleanup-old-images.py <repository> -d --include-untagged        # also clean up untagged orphan images
        uv run cleanup-old-images.py <repository> <repository/N> -d --check-ecs --check-lambda --check-eks
        uv run cleanup-old-images.py --all -d --check-ecs --check-lambda --check-eks --verbose
        uv run cleanup-old-images.py --all -d -o json | jq '.repositories[].candidates[].digest'
    - archive:
        uv run cleanup-old-images.py <repository> --archive                    # dry-run
        uv run cleanup-old-images.py <repository> -a --execute                 # effectively archive
        uv run cleanup-old-images.py <repository> -a --older-than 60
    - plan for later:
        uv run cleanup-old-images.py <repository> -d --check-eks --plan-file plan.json   # save results as the plan
        uv run cleanup-old-images.py <repository> -a --plan-file plan.json               # archive plan
        uv run cleanup-old-images.py --plan-file plan.json --execute                     # apply a saved plan
        uv run cleanup-old-images.py --plan-file plan.json --execute --force             # apply, and skip warnings
"""

import argparse
import base64
import dataclasses
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from typing import NamedTuple
from datetime import datetime, timedelta, timezone
import fnmatch
import io
import json
import logging
import os
import shutil
import ssl
import sys
import tempfile
import urllib.error
import urllib.request

import boto3
from botocore.exceptions import ClientError
from botocore.signers import RequestSigner
import yaml
from rich.console import Console
from rich.progress import (
    BarColumn,
    MofNCompleteColumn,
    Progress,
    SpinnerColumn,
    TextColumn,
)
from rich.table import Table
from rich import box as _rich_box
from rich.text import Text as _Text

_log_main = logging.getLogger("ECR")
_log_ecs = logging.getLogger("ECS")
_log_lambda = logging.getLogger("Lambda")
_log_eks = logging.getLogger("EKS")


# ── grouped verbose output for parallel consumer checks ───────────────────────


def _captured(fn, logger_name: str) -> tuple:

    """
    Run a given function with logging for logger_name buffered into a StringIO.

    Temporarily disables propagation on the named logger to store records in the
    in-memory stream only. The caller writes the buffer to stderr after the
    future completes, producing grouped output regardless of execution order.
    """

    buf = io.StringIO()
    handler = logging.StreamHandler(buf)
    handler.setFormatter(logging.Formatter("[%(name)s] %(message)s"))
    logger = logging.getLogger(logger_name)
    propagate = logger.propagate
    logger.addHandler(handler)
    logger.propagate = False
    try:
        result = fn()
    finally:
        logger.removeHandler(handler)
        logger.propagate = propagate
    return result, buf.getvalue()


INDEX_MEDIA_TYPES = {
    "application/vnd.docker.distribution.manifest.list.v2+json",
    "application/vnd.oci.image.index.v1+json",
}


# ── domain objects ─────────────────────────────────────────────────────────────


@dataclass
class Image:
    digest: str
    tags: list[str]
    pushed_at: datetime | None
    last_pull: datetime | None
    size_bytes: int
    media_type: str | None = None
    image_status: str | None = None         # ACTIVE | ARCHIVED | ACTIVATING
    last_archived_at: datetime | None = None
    platform: str | None = None             # set only for index children
    children: list["Image"] | None = None   # set only for indices

    @property
    def is_index(self) -> bool:
        return self.media_type in INDEX_MEDIA_TYPES

    @property
    def total_size(self) -> int:
        return self.size_bytes + sum(c.size_bytes for c in (self.children or []))


class RepoAction(NamedTuple):
    repository: str
    candidates: list[Image]
    excluded: list[Image]
    digests: list[str]
    kept: list[Image]


# ── ECR fetching ──────────────────────────────────────────────────────────────


def fetch_repository(ecr, repository: str) -> list[Image]:

    """
    Fetch all images via describe_images only. Avoid batch_get_image calls.

    Returns a flat list of every manifest in the repository, including platform
    children of multi-arch indices. Parent-child resolution is deferred to
    resolve_candidate_children (action path only) to avoid polluting their
    last pull value.

    Indices are identified by their imageManifestMediaType, not by resolved
    children.
    """

    raw = []
    for page in ecr.get_paginator("describe_images").paginate(repositoryName=repository):
        raw.extend(page["imageDetails"])

    raw.sort(
        key=lambda x: x.get("imagePushedAt", datetime.min.replace(tzinfo=timezone.utc))
    )

    return [
        Image(
            digest=r["imageDigest"],
            tags=sorted(r.get("imageTags", [])),
            pushed_at=r.get("imagePushedAt"),
            last_pull=r.get("lastRecordedPullTime"),
            size_bytes=r.get("imageSizeInBytes", 0),
            media_type=r.get("imageManifestMediaType"),
            image_status=r.get("imageStatus"),
            last_archived_at=r.get("lastArchivedAt"),
        )
        for r in raw
    ]


def list_all_repositories(ecr) -> list[str]:

    """
    Return all repository names in the registry, sorted alphabetically.
    """

    repos: list[str] = []
    for page in ecr.get_paginator("describe_repositories").paginate():
        repos.extend(r["repositoryName"] for r in page["repositories"])
    return sorted(repos)


# ── deletion helpers ──────────────────────────────────────────────────────────


def _detect_poisoned_timestamps(
    indices: list[Image],
    window_seconds: int = 60,
    min_cluster: int = 3,
) -> set[str]:

    """
    Return digests of indices whose last_pull is likely a batch_get_image
    artifact from a prior inspection run.

    A sequential batch_get_image loop stamps last_pull within seconds across all
    inspected indices. Treat N+ timestamps within window_seconds of each other
    as a scripted event, not genuine Docker pulls.
    """

    with_pull = sorted(
        [(img.last_pull, img.digest) for img in indices if img.last_pull is not None],
        key=lambda x: x[0],
    )
    poisoned: set[str] = set()
    i = 0
    while i < len(with_pull):
        j = i + 1
        while (
            j < len(with_pull)
            and (with_pull[j][0] - with_pull[i][0]).total_seconds() < window_seconds
        ):
            j += 1
        if j - i >= min_cluster:
            for _, digest in with_pull[i:j]:
                poisoned.add(digest)
        i = j
    return poisoned


def find_candidates(
    images: list[Image],
    older_than_days: int,
    keep_last: int = 1,
) -> tuple[list[Image], list[Image]]:

    """
    Identify stale images as deletion/archive candidates.

    Returns (candidates, kept). kept contains images excluded because they were
    pulled recently OR because they are in the top keep_last by push date.
    Skips untagged non-indices (likely platform children) so that they appear
    in neither list.

    Each category sends a different signal:

    - indices: last_pull is unreliable, possibly poisoned by batch_get_image in
      previous runs. _detect_poisoned_timestamps identifies suspect timestamps
      by clustering. For trustworthy last_pull, use the standard recency check.
      For poisoned last_pull, fall back to pushed_at signals (rots, but consumer
      checks act as safety net).

    - Standalone tagged non-indices: last_pull is clean (batch_get_image is
      never called on platform manifests). Standard recency check applies.

    - Untagged non-indices: likely platform children of some index. Skipped
      here, included in deletion via resolve_candidate_children after
      identifying candidate indices. Repos with untagged standalone orphans
      (not children of any index) can opt in via --include-untagged, which
      calls find_orphan_untagged_candidates after the standard pipeline.
    """

    cutoff = datetime.now(timezone.utc) - timedelta(days=older_than_days)
    epsilon = timedelta(days=7)

    # ECR archive tier has a 90-day minimum billing period; deleting earlier
    # still incurs the full charge.
    archive_min_days = 90
    archive_cutoff = datetime.now(timezone.utc) - timedelta(days=archive_min_days)

    # Protect the N most recently pushed top-level images unconditionally.
    protected_by_count: set[str] = set()
    if keep_last > 0:
        sortable = [img for img in images if img.is_index or img.tags]
        sortable.sort(
            key=lambda x: x.pushed_at or datetime.min.replace(tzinfo=timezone.utc),
            reverse=True,
        )
        protected_by_count = {img.digest for img in sortable[:keep_last]}

    indices = [img for img in images if img.is_index]
    poisoned = _detect_poisoned_timestamps(indices)
    if poisoned:
        _log_main.info(
            "%d index last_pull timestamp(s) look like prior inspection artifacts; "
            "using pushed_at signals for those",
            len(poisoned),
        )

    candidates: list[Image] = []
    kept: list[Image] = []

    def _classify(img: Image) -> None:
        recently = (
            (img.last_pull is not None and img.last_pull >= cutoff)
            or (img.pushed_at is not None and img.pushed_at >= cutoff)
        )
        if recently:
            kept.append(img)
        else:
            candidates.append(img)

    for img in images:
        if img.digest in protected_by_count:
            kept.append(img)
            continue
        if img.image_status == "ARCHIVED":
            if img.last_archived_at is None or img.last_archived_at >= archive_cutoff:
                kept.append(img)
                continue
        if img.is_index:
            if img.digest in poisoned:
                deploy_once = (
                    img.last_pull is not None
                    and img.pushed_at is not None
                    and img.pushed_at < cutoff
                    and (img.last_pull - img.pushed_at) < epsilon
                )
                if (
                    img.last_pull is None
                    or deploy_once
                    or (img.pushed_at is not None and img.pushed_at < cutoff)
                ):
                    candidates.append(img)
                else:
                    kept.append(img)
            else:
                _classify(img)
        elif img.tags:
            # Standalone tagged single-arch: last_pull is a reliable signal.
            _classify(img)
        # Untagged non-index (likely a platform child manifest): skip.
        # These are included in deletion as children of candidate indices.

    return candidates, kept


def find_orphan_untagged_candidates(
    ecr,
    repository: str,
    images: list[Image],
    known_child_digests: set[str],
    older_than_days: int,
) -> list[Image]:

    """
    Return untagged non-index images not referenced by any index in a
    repository.

    Resolves all index manifests not already resolved (non-candidate indices)
    via batch_get_image to build a complete parent-child map. This poisons
    lastRecordedPullTime on those indices; acceptable when the caller opts in
    with --include-untagged.

    known_child_digests includes child digests already populated by
    resolve_candidate_children. Orphan candidates pass through the standard age
    gate (age > older_than_days). --keep-last does not apply to untagged orphans
    since they are not part of any tagged deployment sequence.
    """

    untagged_non_indices = [
        img for img in images
        if not img.is_index and not img.tags and img.digest not in known_child_digests
    ]
    if not untagged_non_indices:
        return []

    # Resolve index manifests not yet resolved (non-candidate / kept indices).
    unresolved_indices = [img for img in images if img.is_index and img.children is None]
    if unresolved_indices:
        _log_main.info(
            "Resolving %d non-candidate index(es) in %s to identify orphaned images",
            len(unresolved_indices),
            repository,
        )
        index_by_digest = {img.digest: img for img in unresolved_indices}
        for i in range(0, len(unresolved_indices), 100):
            batch = unresolved_indices[i : i + 100]
            resp = ecr.batch_get_image(
                repositoryName=repository,
                imageIds=[{"imageDigest": img.digest} for img in batch],
                acceptedMediaTypes=list(INDEX_MEDIA_TYPES),
            )
            for item in resp.get("images", []):
                digest = item["imageId"]["imageDigest"]
                idx = index_by_digest.get(digest)
                if idx is None:
                    continue
                manifest = json.loads(item["imageManifest"])
                idx.children = [
                    Image(
                        digest=entry["digest"],
                        tags=[],
                        pushed_at=None,
                        last_pull=None,
                        size_bytes=0,
                    )
                    for entry in manifest.get("manifests", [])
                ]
            for failure in resp.get("failures", []):
                digest = failure.get("imageId", {}).get("imageDigest", "?")
                idx = index_by_digest.get(digest)
                if idx is not None:
                    idx.children = []
                _log_main.warning(
                    "Failed to resolve non-candidate index %s: %s",
                    digest[:19],
                    failure.get("failureReason", "?"),
                )

    # Build complete child digest set (candidate children + newly-resolved non-candidate children).
    all_child_digests = known_child_digests | {
        c.digest
        for img in images
        if img.is_index
        for c in (img.children or [])
    }

    cutoff = datetime.now(timezone.utc) - timedelta(days=older_than_days)
    orphans: list[Image] = []
    for img in untagged_non_indices:
        if img.digest in all_child_digests:
            continue
        recently = (
            (img.last_pull is not None and img.last_pull >= cutoff)
            or (img.pushed_at is not None and img.pushed_at >= cutoff)
        )
        if not recently:
            orphans.append(img)

    if orphans:
        _log_main.info(
            "%d untagged orphan image(s) identified as candidates in %s",
            len(orphans),
            repository,
        )
    return orphans


def resolve_candidate_children(
    ecr,
    repository: str,
    candidates: list[Image],
    all_images: list[Image],
) -> None:

    """
    Populate .children on candidate index images in-place.

    Calls batch_get_image only on candidate indices. Never touches non-candidate
    indices to avoid affecting their lastRecordedPullTime in this run.
    all_images provides the metadata (size, tags, timestamps) for child lookup.

    Resolve all candidate indices in a single batched call (chunked at 100)
    rather than one call per index. batch_get_image poisons lastRecordedPullTime
    on every index it touches, but batching stamps them all at the same instant,
    which produces a tighter timestamp cluster (more detectable by
    _detect_poisoned_timestamps on the next run, not less).
    Candidate timestamps do not affect the current run's survival decisions,
    since candidates are already committed to deletion before this function
    is called.
    """

    by_digest = {img.digest: img for img in all_images}
    candidate_indices = [img for img in candidates if img.is_index]
    if not candidate_indices:
        return

    _log_main.info(
        "Resolving children for %d candidate index(es) in %s",
        len(candidate_indices),
        repository,
    )

    index_by_digest = {img.digest: img for img in candidate_indices}
    for img in candidate_indices:
        img.children = []  # default; overwritten below if manifest resolves

    for i in range(0, len(candidate_indices), 100):
        batch = candidate_indices[i : i + 100]
        resp = ecr.batch_get_image(
            repositoryName=repository,
            imageIds=[{"imageDigest": img.digest} for img in batch],
            acceptedMediaTypes=list(INDEX_MEDIA_TYPES),
        )
        for item in resp.get("images", []):
            digest = item["imageId"]["imageDigest"]
            img = index_by_digest.get(digest)
            if img is None:
                continue
            manifest = json.loads(item["imageManifest"])
            children = []
            for entry in manifest.get("manifests", []):
                plat = entry.get("platform", {})
                arch = plat.get("architecture", "?")
                variant = plat.get("variant", "")
                os_ = plat.get("os", "?")
                platform = f"{os_}/{arch}" + (f"/{variant}" if variant else "")
                child_digest = entry["digest"]
                raw_child = by_digest.get(child_digest)
                if raw_child is None:
                    continue
                children.append(
                    Image(
                        digest=child_digest,
                        tags=sorted(raw_child.tags),
                        pushed_at=raw_child.pushed_at,
                        last_pull=raw_child.last_pull,
                        size_bytes=raw_child.size_bytes,
                        platform=platform,
                    )
                )
            img.children = children
        for f in resp.get("failures", []):
            digest = f.get("imageId", {}).get("imageDigest", "?")
            _log_main.warning("Failed to resolve index %s: %s", digest[:19], f.get("failureReason", "?"))


def deletion_digests(candidates: list[Image], all_images: list[Image]) -> list[str]:

    """
    Expand index candidates to include their children, but only emit a child
    manifest when every parent index that references it is also being deleted.

    ECR is content-addressed. Two indices can share the same child manifest by
    its digest. Deleting a shared child while a non-candidate parent still
    references it would break that parent.

    Note: the shared-child safety check is limited to candidate indices (those
    whose children have been resolved by resolve_candidate_children).
    Non-candidate indices are not resolved, so cross-candidate sharing is not
    detected. This is an accepted tradeoff; consumer checks (--check-eks etc.)
    provide the primary safety net.
    """

    candidate_digests = {img.digest for img in candidates}
    child_parents: dict[str, set[str]] = {}
    for img in all_images:
        if img.is_index:
            for c in img.children or []:
                child_parents.setdefault(c.digest, set()).add(img.digest)
    result: list[str] = []
    seen: set[str] = set()
    for img in candidates:
        if img.digest not in seen:
            seen.add(img.digest)
            result.append(img.digest)
        for child in img.children or []:
            if child.digest in seen:
                continue
            if child_parents.get(child.digest, set()) <= candidate_digests:
                seen.add(child.digest)
                result.append(child.digest)
    return result


def execute_delete(ecr, repository: str, digests: list[str], total_size_bytes: int = 0) -> None:

    """
    Delete ECR images by digest.

    Chunks into batches of 100, since batch_delete_image accepts at most 100
    image IDs per call.
    """

    total_deleted = 0
    for i in range(0, len(digests), 100):
        batch = digests[i : i + 100]
        resp = ecr.batch_delete_image(
            repositoryName=repository,
            imageIds=[{"imageDigest": d} for d in batch],
        )
        total_deleted += len(
            {r["imageDigest"] for r in resp.get("imageIds", []) if "imageDigest" in r}
        )
        for f in resp.get("failures", []):
            img_id = f.get("imageId", {})
            print(
                f"  FAILED {img_id.get('imageDigest', '?')[:19]} — {f['failureCode']}: {f['failureReason']}"
            )
    size_note = f", {_size(total_size_bytes)}" if total_size_bytes else ""
    print(f"Deleted: {repository}: {total_deleted}/{len(digests)} digest(s){size_note}")


def execute_archive(ecr, repository: str, digests: list[str], total_size_bytes: int = 0) -> None:

    """
    Archive ECR images by digest.

    There is currently no batch equivalent for update_image_storage_class; one
    call per digest is required, not a choice.
    """

    succeeded = 0
    skipped = 0
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        MofNCompleteColumn(),
        console=Console(stderr=True, highlight=False),
        transient=True,
    ) as progress:
        archive_task = progress.add_task(f"Archiving {repository}", total=len(digests))
        for digest in digests:
            try:
                resp = ecr.update_image_storage_class(
                    repositoryName=repository,
                    imageId={"imageDigest": digest},
                    targetStorageClass="ARCHIVE",
                )
            except ecr.exceptions.ImageStorageClassUpdateNotSupportedException:
                skipped += 1
                progress.advance(archive_task)
                continue
            status = resp.get("imageStatus", "?")
            if status in ("ARCHIVED", "ACTIVATING"):
                succeeded += 1
            else:
                print(f"  UNEXPECTED STATUS {digest[:19]} — {status}")
            progress.advance(archive_task)
    skip_note = f" ({skipped} skipped — referenced by active index)" if skipped else ""
    size_note = f", {_size(total_size_bytes)}" if total_size_bytes else ""
    print(f"Archived: {repository}: {succeeded}/{len(digests)} digest(s){size_note}{skip_note}")


def _run_execute_plan(ecr, plan_file: str, force: bool) -> None:

    """
    Execute a deletion or archive plan previously saved via --plan-file
    (dry-run).

    Action and target repositories are read from the plan file. Candidate
    recomputation and consumer checks are skipped; the saved digests are the
    source of truth.

    Warns and exits if the plan was saved without consumer checks, unless
    --force is passed. This mirrors the same guard on bare --execute.
    """

    with open(plan_file) as f:
        plan = json.load(f)

    action = plan.get("action")
    if action not in ("delete", "archive"):
        print(f"error: plan file has unknown action {action!r}", file=sys.stderr)
        sys.exit(1)

    consumer_checks = plan.get("consumer_checks", [])
    if not consumer_checks and not force:
        print(
            "warning: plan was saved without consumer checks; "
            "add --force to execute anyway, or re-generate with "
            "--check-eks/--check-ecs/--check-lambda",
            file=sys.stderr,
        )
        sys.exit(1)

    created_at = plan.get("created_at", "unknown")
    repos = plan.get("repositories", [])
    summary = plan.get("summary", {})

    print(
        f"\nExecuting plan from {plan_file!r}  (saved {created_at})\n"
        f"  action={action}  "
        f"repos={summary.get('repository_count', '?')}  "
        f"images={summary.get('total_candidates', '?')}  "
        f"digests={summary.get('total_digests', '?')}  "
        f"size={_size(summary.get('total_size_bytes', 0))}\n"
    )

    for entry in repos:
        repo = entry["repository"]
        digests = entry.get("digests_to_delete", [])
        if not digests:
            continue
        size = entry.get("total_size_bytes", 0)
        if action == "delete":
            execute_delete(ecr, repo, digests, total_size_bytes=size)
        else:
            execute_archive(ecr, repo, digests, total_size_bytes=size)


# ── consumer protection ───────────────────────────────────────────────────────


def _collect_ecr_digest(ecr, image: str, in_use: dict[str, set[str]]) -> bool:

    """
    Parse an ECR image URI and record (repo, digest) into in_use.

    Returns True if a new digest was recorded; False otherwise (no match,
    malformed URI, or duplicate digest already in the set).

    Handles tag-only, digest-only, and tag+digest (<repo>:<tag>@<digest>) forms.
    Strips the docker-pullable:// prefix used by older container runtimes.
    """

    image = image.removeprefix("docker-pullable://")
    if not image or ".dkr.ecr." not in image or "/" not in image:
        return False
    _, rest = image.split("/", 1)
    if "@" in rest:
        ref, digest = rest.split("@", 1)
        repo_part = ref.rsplit(":", 1)[0] if ":" in ref else ref
        tag = None
    elif ":" in rest:
        repo_part, tag, digest = *rest.rsplit(":", 1), None
    else:
        repo_part, tag, digest = rest, "latest", None
    if digest:
        bucket = in_use.setdefault(repo_part, set())
        if digest in bucket:
            return False
        bucket.add(digest)
        return True
    elif tag:
        try:
            added = False
            for d in ecr.describe_images(
                repositoryName=repo_part,
                imageIds=[{"imageTag": tag}],
            ).get("imageDetails", []):
                bucket = in_use.setdefault(repo_part, set())
                if d["imageDigest"] not in bucket:
                    bucket.add(d["imageDigest"])
                    added = True
            return added
        except ClientError as e:
            code = e.response["Error"]["Code"]
            if code not in ("ImageNotFoundException", "RepositoryNotFoundException"):
                raise
            return False
    return False


def fetch_ecs_digests(ecr, ecs) -> dict[str, set[str]]:

    """
    Return all ECR digests actively referenced by ECS, grouped by repo.

    Two passes per cluster:
    1. Services → active task definitions (desired state; covers pending tasks
       which containers have not pulled yet).
    2. Currently running tasks via list_tasks + describe_tasks (running state;
       covers old revisions still alive during a rolling deployment).
    """

    _log_ecs.info("Scanning clusters...")
    task_def_arns: set[str] = set()
    in_use: dict[str, set[str]] = {}
    for page in ecs.get_paginator("list_clusters").paginate():
        for cluster in page["clusterArns"]:
            cluster_short = cluster.split("/")[-1]

            # Pass 1: desired state, service active task definitions
            arns: list[str] = []
            for p in ecs.get_paginator("list_services").paginate(cluster=cluster):
                arns.extend(p["serviceArns"])
            cluster_task_defs: set[str] = set()
            for i in range(0, len(arns), 10):  # describe_services, max 10 per call
                for svc in ecs.describe_services(cluster=cluster, services=arns[i : i + 10])["services"]:
                    if svc.get("taskDefinition"):
                        cluster_task_defs.add(svc["taskDefinition"])
            task_def_arns |= cluster_task_defs
            _log_ecs.info(
                "  %s: %d service(s), %d task def(s)",
                cluster_short,
                len(arns),
                len(cluster_task_defs),
            )

            # Pass 2: running state.
            # desiredStatus=RUNNING covers PROVISIONING/ACTIVATING/RUNNING;
            # imageDigest is set after the container pulls the image, so we need
            # to fall back to image URI for pending ones.
            running_arns: list[str] = []
            for p in ecs.get_paginator("list_tasks").paginate(
                cluster=cluster,
                desiredStatus="RUNNING",
            ):
                running_arns.extend(p["taskArns"])
            for i in range(0, len(running_arns), 100):  # describe_tasks, max 100 per call
                for task in ecs.describe_tasks(cluster=cluster, tasks=running_arns[i : i + 100])["tasks"]:
                    task_id = task.get("taskArn", "?").split("/")[-1]
                    for container in task.get("containers", []):
                        img = container.get("image", "")
                        img_digest = container.get("imageDigest", "")
                        # Only append imageDigest when img is a tag-only reference;
                        # @sha256:... URIs are already pinned by the digest.
                        uri = (
                            f"{img}@{img_digest}"
                            if img and img_digest and "@" not in img
                            else img
                        )
                        if uri and _collect_ecr_digest(ecr, uri, in_use):
                            _log_ecs.info(
                                "  match (running): %s/%s -> %s",
                                task_id,
                                container.get("name", "?"),
                                uri,
                            )
            _log_ecs.info("  %s: %d running task(s) scanned", cluster_short, len(running_arns))

    def _fetch_td(td_arn: str) -> tuple[str, dict[str, set[str]], list[str]]:
        td = ecs.describe_task_definition(taskDefinition=td_arn)["taskDefinition"]
        parts = td_arn.split(":")
        td_short = (f"{parts[-2].split('/')[-1]}:{parts[-1]}" if len(parts) >= 2 else td_arn)
        local: dict[str, set[str]] = {}
        matches: list[str] = []
        for container in td.get("containerDefinitions", []):
            image = container.get("image", "")
            if _collect_ecr_digest(ecr, image, local):
                matches.append(image)
        return td_short, local, matches

    if task_def_arns:
        with ThreadPoolExecutor(max_workers=min(len(task_def_arns), 10)) as ex:
            for fut in as_completed(ex.submit(_fetch_td, arn) for arn in task_def_arns):
                td_short, local, matches = fut.result()
                for image in matches:
                    _log_ecs.info("  match (task def): %s  (%s)", image, td_short)
                for repo, digests in local.items():
                    in_use.setdefault(repo, set()).update(digests)

    total = sum(len(v) for v in in_use.values())
    _log_ecs.info("%d digest(s) across %d repo(s)", total, len(in_use))
    return in_use


def fetch_lambda_digests(ecr, lambda_client) -> dict[str, set[str]]:

    """
    Return all ECR digests referenced by Lambda image functions, grouped by
    repository.

    Checks $LATEST configuration only. Published versions pointed to by aliases
    are not inspected; they would require an extra list_aliases + versioned
    get_function pass.
    """

    _log_lambda.info("Scanning image functions...")
    in_use: dict[str, set[str]] = {}
    fn_count = 0
    for page in lambda_client.get_paginator("list_functions").paginate():
        for fn in page["Functions"]:
            if fn.get("PackageType") != "Image":
                continue
            fn_count += 1
            code = lambda_client.get_function(FunctionName=fn["FunctionName"]).get("Code", {})
            uri = code.get("ResolvedImageUri") or code.get("ImageUri", "")
            if _collect_ecr_digest(ecr, uri, in_use):
                _log_lambda.info("  match: %s -> %s", fn["FunctionName"], uri)
    total = sum(len(v) for v in in_use.values())
    _log_lambda.info(
        "%d image function(s) scanned, %d digest(s) across %d repo(s)",
        fn_count,
        total,
        len(in_use),
    )
    return in_use


def _eks_token(cluster_name: str, region: str, session) -> str:

    """
    Generate an EKS bearer token (equivalent to aws eks get-token).

    Uses a SigV4-presigned STS GetCallerIdentity URL (standard EKS
    authentication mechanism).
    """

    sts = session.client("sts", region_name=region)
    signer = RequestSigner(
        sts.meta.service_model.service_id,
        region,
        "sts",
        "v4",
        session.get_credentials(),
        session.events,
    )
    signed_url = signer.generate_presigned_url(
        {
            "method": "GET",
            "url": f"https://sts.{region}.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15",
            "body": {},
            "headers": {"x-k8s-aws-id": cluster_name},
            "context": {},
        },
        region_name=region,
        expires_in=60,
        operation_name="",
    )
    return "k8s-aws-v1." + base64.urlsafe_b64encode(signed_url.encode()).decode().rstrip("=")


def fetch_eks_digests(ecr, eks_client, region: str, session) -> dict[str, set[str]]:

    """
    Return digests in use by pods across all EKS clusters.

    Queries /api/v1/pods on each cluster's Kubernetes API server. Private
    clusters are only reachable from within the cluster's VPC.
    Unreachable clusters are skipped with a stderr warning.
    Checks both status.containerStatuses[].imageID (resolved digest, set after
    pull) and spec.containers[].image (covers pending containers before imageID
    is populated).
    """

    in_use: dict[str, set[str]] = {}
    cluster_names: list[str] = []
    for page in eks_client.get_paginator("list_clusters").paginate():
        cluster_names.extend(page["clusters"])

    _log_eks.info("Scanning %d cluster(s)...", len(cluster_names))

    for cluster_name in cluster_names:
        _log_eks.info("  cluster: %s", cluster_name)
        cluster = eks_client.describe_cluster(name=cluster_name)["cluster"]
        endpoint = cluster["endpoint"]
        ca_data = cluster["certificateAuthority"]["data"]
        token = _eks_token(cluster_name, region, session)

        ca_path = None
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix=".crt") as f:
                f.write(base64.b64decode(ca_data))
                ca_path = f.name
            ctx = ssl.create_default_context(cafile=ca_path)
            req = urllib.request.Request(
                f"{endpoint}/api/v1/pods",
                headers={"Authorization": f"Bearer {token}"},
            )
            with urllib.request.urlopen(req, context=ctx, timeout=30) as resp:
                pod_list = json.loads(resp.read())
        except urllib.error.URLError as e:
            _log_eks.warning("skipping cluster %r: %s", cluster_name, e.reason)
            continue
        finally:
            if ca_path:
                os.unlink(ca_path)

        before_cluster = sum(len(v) for v in in_use.values())
        verbose_pods = _log_eks.isEnabledFor(logging.INFO)
        for pod in pod_list.get("items", []):
            pod_name = pod.get("metadata", {}).get("name", "?") if verbose_pods else ""
            status = pod.get("status", {})
            for cs in (status.get("containerStatuses") or []) + (status.get("initContainerStatuses") or []):
                image_id = cs.get("imageID", "")
                if _collect_ecr_digest(ecr, image_id, in_use):
                    _log_eks.info(
                        "    match (imageID): %s/%s -> %s",
                        pod_name,
                        cs.get("name", "?"),
                        image_id,
                    )
            spec = pod.get("spec", {})
            for c in (spec.get("containers") or []) + (spec.get("initContainers") or []):
                image = c.get("image", "")
                if _collect_ecr_digest(ecr, image, in_use):
                    _log_eks.info(
                        "    match (spec):    %s/%s -> %s",
                        pod_name,
                        c.get("name", "?"),
                        image,
                    )

        matched = sum(len(v) for v in in_use.values()) - before_cluster
        _log_eks.info("  %d pod(s), %d new digest(s)", len(pod_list.get("items", [])), matched)

    total = sum(len(v) for v in in_use.values())
    _log_eks.info("%d digest(s) across %d repo(s)", total, len(in_use))
    return in_use


def exclude_in_use(candidates: list[Image], in_use: set[str]) -> tuple[list[Image], list[Image]]:

    """
    Split candidates into (to_act_on, excluded).

    Excludes an image if its digest or any child digest appears in in_use.
    """

    active, excluded = [], []
    for img in candidates:
        digests = {img.digest} | {c.digest for c in (img.children or [])}
        if digests & in_use:
            excluded.append(img)
        else:
            active.append(img)
    return active, excluded


def exclude_manual(
    candidates: list[Image],
    exclude_tags: list[str],
    exclude_digests: list[str],
) -> tuple[list[Image], list[Image]]:

    """
    Split candidates into (to_act_on, excluded_by_rule).

    --exclude-tag    PATTERN  fnmatch glob against top-level tags
                              (e.g. "latest", "v*")
    --exclude-digest DIGEST   full or short-prefix match; sha256: prefix is
                              optional

    ECR allows any manifest (including index children) to carry imageTags.
    However, fetch_repository excludes child digests from the candidate list, so
    --exclude-tag only sees top-level images. A tagged child whose parent is a
    candidate but has no matching tag is not reachable via --exclude-tag; use
    --exclude-digest for that edge case.
    """

    if not exclude_tags and not exclude_digests:
        return candidates, []

    # Normalise digest-based references by striping sha256: so both "sha256:abc12" and "abc12" match.
    norm_refs = [r.removeprefix("sha256:") for r in exclude_digests]

    active, excluded = [], []
    for img in candidates:
        matched = any(fnmatch.fnmatchcase(t, p) for p in exclude_tags for t in img.tags)
        if not matched and norm_refs:
            all_digests = {img.digest} | {c.digest for c in (img.children or [])}
            norm_digests = {d.removeprefix("sha256:") for d in all_digests}
            matched = any(nd.startswith(ref) for nd in norm_digests for ref in norm_refs)
        (excluded if matched else active).append(img)
    return active, excluded


# ── serialization ─────────────────────────────────────────────────────────────


def _serialize(obj):
    if isinstance(obj, datetime):
        return obj.isoformat()
    if isinstance(obj, list):
        return [_serialize(i) for i in obj]
    if dataclasses.is_dataclass(obj):
        return {k: _serialize(v) for k, v in vars(obj).items()}
    return obj


def _deserialize_images(data: list[dict]) -> list[Image]:

    """
    Reconstruct a flat list[Image] from a cache file written by _serialize.

    Children are not stored in the flat cache (they are None in the output of
    fetch_repository), so they are left as None here too.
    """

    def _dt(s: str | None) -> datetime | None:
        return datetime.fromisoformat(s) if s else None

    return [
        Image(
            digest=d["digest"],
            tags=d.get("tags") or [],
            pushed_at=_dt(d.get("pushed_at")),
            last_pull=_dt(d.get("last_pull")),
            size_bytes=d.get("size_bytes", 0),
            media_type=d.get("media_type"),
            image_status=d.get("image_status"),
            last_archived_at=_dt(d.get("last_archived_at")),
            platform=d.get("platform"),
        )
        for d in data
    ]


def _cache_path(cache_dir: str, repository: str) -> str:
    slug = repository.replace("/", "__")
    return os.path.join(cache_dir, f"{slug}.json")


def _load_cache(cache_dir: str, repository: str) -> list[Image] | None:
    path = _cache_path(cache_dir, repository)
    if not os.path.exists(path):
        return None
    with open(path) as f:
        return _deserialize_images(json.load(f))


def _save_cache(cache_dir: str, repository: str, images: list[Image]) -> None:
    os.makedirs(cache_dir, exist_ok=True)
    path = _cache_path(cache_dir, repository)
    with open(path, "w") as f:
        json.dump([_serialize(img) for img in images], f, indent=2)


def listing_as_dict(per_repo: list[tuple[str, list[Image]]]) -> dict:
    repositories = []
    grand_count = 0
    grand_size = 0
    for repo, images in per_repo:
        total_size = sum(img.total_size for img in images)
        total_count = sum(1 + len(img.children or []) for img in images)
        repositories.append(
            {
                "repository": repo,
                "total_images": total_count,
                "total_size_bytes": total_size,
                "images": [_serialize(img) for img in images],
            }
        )
        grand_count += total_count
        grand_size += total_size
    return {
        "repositories": repositories,
        "summary": {
            "repository_count": len(per_repo),
            "total_images": grand_count,
            "total_size_bytes": grand_size,
        },
    }


def action_plan_as_dict(
    per_repo: list[RepoAction],
    older_than_days: int,
    dry_run: bool,
    action: str,
    keep_last: int = 1,
) -> dict:
    repositories = []
    grand_candidates = 0
    grand_digests = 0
    grand_size = 0
    for repo, candidates, excluded, digests, _kept in per_repo:
        total_size = sum(img.total_size for img in candidates)
        repositories.append(
            {
                "repository": repo,
                "total_candidates": len(candidates),
                "total_digests": len(digests),
                "total_size_bytes": total_size,
                "candidates": [_serialize(img) for img in candidates],
                "digests_to_delete": digests,
                "protected": [_serialize(img) for img in excluded],
            }
        )
        grand_candidates += len(candidates)
        grand_digests += len(digests)
        grand_size += total_size
    return {
        "action": action,
        "dry_run": dry_run,
        "older_than_days": older_than_days,
        "keep_last": keep_last,
        "repositories": repositories,
        "summary": {
            "repository_count": len(per_repo),
            "total_candidates": grand_candidates,
            "total_digests": grand_digests,
            "total_size_bytes": grand_size,
        },
    }


def emit(data: dict, fmt: str) -> None:
    if fmt == "json":
        print(json.dumps(data, indent=2))
    elif fmt == "yaml":
        print(yaml.dump(data, default_flow_style=False, sort_keys=False, allow_unicode=True))


# ── table renderers ───────────────────────────────────────────────────────────


_console = Console(
    highlight=False,
    width=max(shutil.get_terminal_size(fallback=(120, 24)).columns, 120),
)
_SYM_STYLE: dict[str, str] = {
    "[-]": "bold red",
    "[~]": "bold yellow",
    "[=]": "dim",
    "[+]": "dim green",
}


def _tag_text(sym: str | None, content: str) -> _Text:
    t = _Text()
    if sym:
        t.append(sym + " ", style=_SYM_STYLE.get(sym, ""))
    t.append(content)
    return t


def _child_text(tree: str, sym: str | None, platform: str, tags: str) -> _Text:
    t = _Text()
    t.append(f"  {tree} ")
    if sym:
        t.append(sym + " ", style=_SYM_STYLE.get(sym, ""))
    t.append(f"{platform:<16}{tags}")
    return t


def _make_table() -> Table:
    t = Table(box=_rich_box.SIMPLE_HEAD, show_edge=False, pad_edge=False, header_style="bold")
    t.add_column("TAGS", min_width=40, no_wrap=True)
    t.add_column("PUSHED", no_wrap=True)
    t.add_column("LAST PULL", no_wrap=True)
    t.add_column("SIZE", no_wrap=True)
    t.add_column("DIGEST", no_wrap=True)
    return t


def _render_repo_listing(images: list[Image], repository: str) -> None:
    total_size = sum(img.total_size for img in images)
    total_count = sum(1 + len(img.children or []) for img in images)
    t = _make_table()
    for img in images:
        tags = ", ".join(img.tags) or "[untagged]"
        t.add_row(
            _tag_text(None, f"{tags} [index]" if img.is_index else tags),
            _age(img.pushed_at),
            _age(img.last_pull),
            _size(img.size_bytes),
            img.digest[:19],
        )
        for i, child in enumerate(img.children or []):
            tree = "└─" if i == len(img.children) - 1 else "├─"
            child_tags = ", ".join(child.tags) or "[untagged]"
            t.add_row(
                _child_text(tree, None, child.platform, child_tags),
                _age(child.pushed_at),
                _age(child.last_pull),
                _size(child.size_bytes),
                child.digest[:19],
            )
    print(f"\nRepository: {repository}  ({total_count} images)\n")
    _console.print(t)
    print(f"Total: {total_count} images, {_size(total_size)}\n")


def render_listing(per_repo: list[tuple[str, list[Image]]]) -> None:
    grand_count = 0
    grand_size = 0
    for repo, images in per_repo:
        _render_repo_listing(images, repo)
        grand_count += sum(1 + len(img.children or []) for img in images)
        grand_size += sum(img.total_size for img in images)
    if len(per_repo) > 1:
        print(f"=== Summary: {len(per_repo)} repositories, {grand_count} images, {_size(grand_size)} ===\n")


def _render_repo_action(
    repository: str,
    candidates: list[Image],
    digests: list[str],
    older_than_days: int,
    dry_run: bool,
    action: str,
    excluded: list[Image],
    kept: list[Image],
    show_kept: bool,
    keep_last: int = 1,
) -> None:
    VERBS = {
        "delete": ("DELETE", "Would delete", "Deleting"),
        "archive": ("ARCHIVE", "Would archive", "Archiving"),
    }
    SYMBOLS = {"delete": "[-]", "archive": "[~]"}
    label_mode, verb_dry, verb_live = VERBS[action]
    sym = SYMBOLS[action]
    label = f"DRY RUN ({label_mode})" if dry_run else label_mode
    excluded = excluded or []
    safe_set = set(digests)

    print(f"\nRepository: {repository}\n")

    if candidates:
        total_size = sum(img.total_size for img in candidates)
        verb = verb_dry if dry_run else verb_live
        n_children = len(digests) - len(candidates)
        unique_children = {c.digest for img in candidates for c in (img.children or [])}
        retained = len(unique_children) - n_children
        child_note = f" + {n_children} child(ren)" if n_children else ""
        retained_note = f" — {retained} shared child(ren) retained" if retained else ""
        print(
            f"[{label}] {verb} {len(candidates)} image(s){child_note}"
            f" = {len(digests)} digest(s), {_size(total_size)}{retained_note}\n"
        )
        t = _make_table()
        for img in candidates:
            tags = ", ".join(img.tags) or "[untagged]"
            t.add_row(
                _tag_text(sym, f"{tags} [index]" if img.is_index else tags),
                _age(img.pushed_at),
                _age(img.last_pull),
                _size(img.size_bytes),
                img.digest[:19],
            )
            for i, child in enumerate(img.children or []):
                tree = "└─" if i == len(img.children) - 1 else "├─"
                child_tags = ", ".join(child.tags) or "[untagged]"
                child_sym = sym if child.digest in safe_set else "[=]"
                t.add_row(
                    _child_text(tree, child_sym, child.platform, child_tags),
                    _age(child.pushed_at),
                    _age(child.last_pull),
                    _size(child.size_bytes),
                    child.digest[:19],
                )
        _console.print(t)
    else:
        print(f"[{label}] No images match criteria (not pulled in {older_than_days}+ days)\n")

    if excluded:
        print(f"\n[PROTECTED] {len(excluded)} image(s) excluded\n")
        t = _make_table()
        for img in excluded:
            tags = ", ".join(img.tags) or "[untagged]"
            t.add_row(
                _tag_text("[=]", f"{tags} [index]" if img.is_index else tags),
                _age(img.pushed_at),
                _age(img.last_pull),
                _size(img.size_bytes),
                img.digest[:19],
            )
            for i, child in enumerate(img.children or []):
                tree = "└─" if i == len(img.children) - 1 else "├─"
                child_tags = ", ".join(child.tags) or "[untagged]"
                t.add_row(
                    _child_text(tree, "[=]", child.platform, child_tags),
                    _age(child.pushed_at),
                    _age(child.last_pull),
                    _size(child.size_bytes),
                    child.digest[:19],
                )
        _console.print(t)

    if kept:
        kept_size = sum(img.size_bytes for img in kept)
        reasons = [f"pulled within {older_than_days} days"]
        if keep_last:
            reasons.append(f"top {keep_last} by push date")
        reason_str = " or ".join(reasons)
        print(
            f"\n[KEPT] {len(kept)} image(s), {_size(kept_size)}"
            f"  ({reason_str} — not candidates)\n"
        )
        if show_kept:
            t = _make_table()
            for img in kept:
                tags = ", ".join(img.tags) or "[untagged]"
                t.add_row(
                    _tag_text("[+]", f"{tags} [index]" if img.is_index else tags),
                    _age(img.pushed_at),
                    _age(img.last_pull),
                    _size(img.size_bytes),
                    img.digest[:19],
                )
            _console.print(t)

    print()


def render_action(
    per_repo: list[RepoAction],
    older_than_days: int,
    dry_run: bool,
    action: str,
    show_kept: bool = False,
    keep_last: int = 1,
) -> None:
    grand_candidates = 0
    grand_digests = 0
    grand_size = 0
    grand_kept = 0
    for repo, candidates, excluded, digests, kept in per_repo:
        _render_repo_action(
            repo,
            candidates,
            digests,
            older_than_days,
            dry_run,
            action,
            excluded,
            kept,
            show_kept,
            keep_last,
        )
        grand_candidates += len(candidates)
        grand_digests += len(digests)
        grand_size += sum(img.total_size for img in candidates)
        grand_kept += len(kept)
    if len(per_repo) > 1:
        verb = f"Would {action}" if dry_run else f"{action.capitalize()}d"
        kept_note = f", {grand_kept} kept" if grand_kept else ""
        print(
            f"=== Summary: {len(per_repo)} repos, {verb} {grand_candidates} image(s)"
            f" = {grand_digests} digest(s), {_size(grand_size)}{kept_note} ===\n"
        )


# ── formatting utils ──────────────────────────────────────────────────────────


def _age(dt: datetime | None) -> str:
    if dt is None:
        return "never"
    days = (datetime.now(timezone.utc) - dt).days
    if days == 0:
        return "today"
    return "1d ago" if days == 1 else f"{days}d ago"


def _size(size_bytes: int) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if size_bytes < 1024:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024
    return f"{size_bytes:.1f} TB"


# ── main ──────────────────────────────────────────────────────────────────────


def main() -> None:
    parser = argparse.ArgumentParser(
        description="List and optionally delete/archive images in ECR repositories"
    )
    parser.add_argument(
        "repositories",
        nargs="*",
        default=[],
        help="repository names; omit and pass --all to process all repos",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        dest="all_repos",
        help="process all repositories in the registry",
    )
    parser.add_argument(
        "--region",
        default="eu-west-1",
        help="aws region (default: eu-west-1)",
    )
    parser.add_argument(
        "--profile",
        help="aws profile (default: default)",
    )
    parser.add_argument(
        "--output",
        "-o",
        choices=["table", "json", "yaml"],
        default="table",
        help="output format (default: table)",
    )
    action_grp = parser.add_mutually_exclusive_group()
    action_grp.add_argument(
        "--delete",
        "-d",
        action="store_true",
        help="delete the candidates",
    )
    action_grp.add_argument(
        "--archive",
        "-a",
        action="store_true",
        help="archive the candidates",
    )
    parser.add_argument(
        "--older-than",
        type=int,
        default=30,
        metavar="DAYS",
        help="limit the action to images older than X days (default: 30)",
    )
    parser.add_argument(
        "--keep-last",
        type=int,
        default=1,
        metavar="N",
        help="always keep the N most recently pushed images per repository, regardless of age (default: 1)",
    )
    parser.add_argument(
        "--execute",
        action="store_true",
        help="take actual action on the candidates",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="suppress the consumer-checks safety warning when using --execute without any --check-* flag",
    )
    parser.add_argument(
        "--plan-file",
        metavar="FILE",
        help="path to a plan JSON file; without --execute: compute the dry-run plan and save it to FILE "
        "(requires --delete or --archive); with --execute: read from FILE and execute it, bypassing "
        "candidate recomputation (--delete/--archive and repository arguments are not needed)",
    )
    parser.add_argument(
        "--max-workers",
        type=int,
        default=10,
        metavar="N",
        help="parallel workers for per-repo fetching (default: 10)",
    )
    parser.add_argument(
        "--cache-dir",
        metavar="DIR",
        help="directory for per-repository cache files; reads from cache when present, writes on first fetch;"
        "delete files in it to force a refresh for those repositories",
    )
    parser.add_argument(
        "--check-ecs",
        action="store_true",
        dest="check_ecs",
        help="exclude images in use by active ECS task definitions",
    )
    parser.add_argument(
        "--check-lambda",
        action="store_true",
        dest="check_lambda",
        help="exclude images in use by Lambda functions (checks $LATEST)",
    )
    parser.add_argument(
        "--check-eks",
        action="store_true",
        dest="check_eks_flag",
        help="exclude images in use by pods across all EKS clusters; requires endpoint access",
    )
    parser.add_argument(
        "--exclude-tag",
        action="append",
        default=[],
        metavar="PATTERN",
        help="protect images with a matching tag (fnmatch globs: 'latest', 'v*'); repeatable",
    )
    parser.add_argument(
        "--exclude-digest",
        action="append",
        default=[],
        metavar="DIGEST",
        help="protect images matching this digest (full sha256:... or short prefix); repeatable",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="print scanning progress and matches to stderr",
    )
    parser.add_argument(
        "--show-kept",
        action="store_true",
        help="show images kept by the age gate or --keep-last (only meaningful with --delete or --archive)",
    )
    parser.add_argument(
        "--include-untagged",
        action="store_true",
        dest="include_untagged",
        help=(
            "also consider untagged non-index images as deletion candidates. "
            "ECR cannot distinguish orphaned standalone images from platform children "
            "via describe_images alone; this flag resolves all non-candidate index "
            "manifests to build a complete parent-child map and treats any untagged "
            "image not referenced by any index as an orphan candidate. "
            "Poisons lastRecordedPullTime on non-candidate indices for the next run. "
            "Safe for repositories with no multi-arch images; use with caution otherwise."
        ),
    )
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO if args.verbose else logging.WARNING,
        stream=sys.stderr,
        format="[%(name)s] %(message)s",
    )
    logging.getLogger("botocore").setLevel(logging.WARNING)

    session = boto3.Session(profile_name=args.profile, region_name=args.region)
    ecr = session.client("ecr")

    # --plan-file + --execute: action and repos come from the plan file, no re-computation
    if args.plan_file and args.execute:
        _run_execute_plan(ecr, args.plan_file, args.force)
        return

    if bool(args.repositories) == bool(args.all_repos):
        parser.error("specify either <repository>(s) positional or --all (not both)")

    # Resolve target repos
    if args.all_repos:
        target_repos = list_all_repositories(ecr)
        _log_main.info("Processing all %d repositories", len(target_repos))
    else:
        target_repos = args.repositories

    action = "delete" if args.delete else "archive" if args.archive else None

    if args.plan_file and not action:
        parser.error("--plan-file without --execute requires --delete or --archive")

    # Run consumer checks ONCE (across the whole registry, not per-repo)
    in_use_by_repo: dict[str, set[str]] = {}
    any_check = args.check_ecs or args.check_lambda or args.check_eks_flag

    if action and args.execute and not any_check and not args.force:
        print(
            "warning: executing without consumer checks; add --check-eks/--check-ecs/--check-lambda "
            "to exclude in-use images, or pass --force to suppress this warning",
            file=sys.stderr,
        )
        sys.exit(1)

    if any_check and not action:
        print(
            "warning: --check-ecs/--check-lambda/--check-eks have no effect without --delete or --archive",
            file=sys.stderr,
        )
    elif any_check:

        def _merge(other: dict[str, set[str]]) -> None:
            for r, digests in other.items():
                in_use_by_repo.setdefault(r, set()).update(digests)

        check_fns = []
        if args.check_ecs:
            check_fns.append(
                lambda: _captured(
                    lambda: fetch_ecs_digests(session.client("ecr"), session.client("ecs")),
                    "ECS",
                )
            )
        if args.check_lambda:
            check_fns.append(
                lambda: _captured(
                    lambda: fetch_lambda_digests(session.client("ecr"), session.client("lambda")),
                    "Lambda",
                )
            )
        if args.check_eks_flag:
            check_fns.append(
                lambda: _captured(
                    lambda: fetch_eks_digests(
                        session.client("ecr"), session.client("eks"), args.region, session
                    ),
                    "EKS",
                )
            )
        with ThreadPoolExecutor(max_workers=len(check_fns)) as ex:
            for fut in as_completed(ex.submit(fn) for fn in check_fns):
                result, log_output = fut.result()
                sys.stderr.write(log_output)
                _merge(result)

    # Parallel per-repo fetch (with optional describe_images cache)
    def _fetch_repo(repo: str) -> list[Image]:
        if args.cache_dir:
            cached = _load_cache(args.cache_dir, repo)
            if cached is not None:
                _log_main.debug("cache hit: %s (%d images)", repo, len(cached))
                return cached
        images = fetch_repository(session.client("ecr"), repo)
        if args.cache_dir:
            _save_cache(args.cache_dir, repo, images)
            _log_main.debug("cache saved: %s", repo)
        return images

    _log_main.info(
        "Fetching %d repo(s) with %d worker(s)...",
        len(target_repos), args.max_workers
    )
    fetched: dict[str, list[Image]] = {}
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        MofNCompleteColumn(),
        console=Console(stderr=True, highlight=False),
        transient=True,
    ) as progress:
        fetch_task = progress.add_task("Fetching repositories", total=len(target_repos))
        with ThreadPoolExecutor(max_workers=args.max_workers) as ex:
            futures = {ex.submit(_fetch_repo, repo): repo for repo in target_repos}
            for fut in as_completed(futures):
                repo = futures[fut]
                try:
                    fetched[repo] = fut.result()
                except Exception as e:
                    _log_main.warning("failed to fetch %s: %s", repo, e)
                    fetched[repo] = []
                progress.advance(fetch_task)

    # Preserve input order
    ordered_listing: list[tuple[str, list[Image]]] = [
        (r, fetched[r]) for r in target_repos if r in fetched
    ]

    if action:
        ordered_action: list[RepoAction] = []
        for repo, images in ordered_listing:
            candidates, kept = find_candidates(images, args.older_than, keep_last=args.keep_last)
            candidates, excluded_manual = exclude_manual(
                candidates, args.exclude_tag, args.exclude_digest
            )
            in_use = in_use_by_repo.get(repo, set())

            # First consumer exclusion: by digest alone, before child resolution.
            # Catches indices or images whose own digest is directly in use.
            candidates, excluded_in_use_1 = exclude_in_use(candidates, in_use)

            # Resolve children only for the remaining candidate indices.
            # batch_get_image is called here, but only on candidates not yet excluded.
            resolve_candidate_children(ecr, repo, candidates, images)

            # Remove any image now confirmed as a child of a candidate index from the
            # top-level candidate list to avoid double-counting in display and digests.
            known_child_digests = {
                c.digest
                for img in candidates
                if img.is_index
                for c in (img.children or [])
            }
            candidates = [
                img for img in candidates if img.digest not in known_child_digests
            ]

            # Second consumer exclusion: now that children are resolved, catch indices
            # whose child digest is in use (e.g. a specific platform manifest pulled by EKS).
            candidates, excluded_in_use_2 = exclude_in_use(candidates, in_use)

            excluded = excluded_manual + excluded_in_use_1 + excluded_in_use_2

            if args.include_untagged:
                orphans = find_orphan_untagged_candidates(
                    ecr, repo, images, known_child_digests, args.older_than
                )
                orphans, excluded_orphan_manual = exclude_manual(
                    orphans, args.exclude_tag, args.exclude_digest
                )
                orphans, excluded_orphan_in_use = exclude_in_use(orphans, in_use)
                candidates.extend(orphans)
                excluded = excluded + excluded_orphan_manual + excluded_orphan_in_use

            digests = deletion_digests(candidates, images)
            ordered_action.append(RepoAction(repo, candidates, excluded, digests, kept))

        dry_run = not args.execute
        if args.output == "table":
            render_action(
                ordered_action,
                args.older_than,
                dry_run,
                action,
                show_kept=args.show_kept,
                keep_last=args.keep_last,
            )
        else:
            emit(
                action_plan_as_dict(ordered_action, args.older_than, dry_run, action, keep_last=args.keep_last),
                args.output,
            )

        if args.plan_file:
            consumer_checks = []
            if args.check_ecs:
                consumer_checks.append("ecs")
            if args.check_lambda:
                consumer_checks.append("lambda")
            if args.check_eks_flag:
                consumer_checks.append("eks")
            plan = action_plan_as_dict(
                ordered_action, args.older_than, dry_run=True, action=action, keep_last=args.keep_last
            )
            plan["consumer_checks"] = consumer_checks
            plan["created_at"] = datetime.now(timezone.utc).isoformat()
            with open(args.plan_file, "w") as f:
                json.dump(plan, f, indent=2)
            print(f"Plan saved to {args.plan_file!r}", file=sys.stderr)

        if args.execute:
            for repo, candidates, _, digests, _kept in ordered_action:
                if not candidates:
                    continue
                size = sum(img.total_size for img in candidates)
                if action == "delete":
                    execute_delete(ecr, repo, digests, total_size_bytes=size)
                else:
                    execute_archive(ecr, repo, digests, total_size_bytes=size)
    else:
        if args.output == "table":
            render_listing(ordered_listing)
        else:
            emit(listing_as_dict(ordered_listing), args.output)


if __name__ == "__main__":
    main()
