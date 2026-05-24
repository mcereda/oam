#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.12"
# dependencies = ["boto3", "pyyaml"]
# ///

"""
List (and optionally delete or archive) images across one or many ECR repositories.

Usage:
    uv run ecr_images.py <repo> [<repo>...]                       # explicit repo list
    uv run ecr_images.py --all                                    # every repo in the registry
    uv run ecr_images.py <repo> -o json
    uv run ecr_images.py <repo> -d                                # dry-run delete
    uv run ecr_images.py <repo> -d --older-than 60
    uv run ecr_images.py <repo> <repo2> -d --check-ecs --check-lambda --check-eks
    uv run ecr_images.py --all -d --check-ecs --check-lambda --check-eks --verbose
    uv run ecr_images.py <repo> -d --execute                      # live delete
    uv run ecr_images.py --all -d -o json | jq '.repositories[].candidates[].digest'
"""

import argparse
import json
import dataclasses
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

import base64
import logging
import os
import ssl
import sys
import tempfile
import urllib.error
import urllib.request

import boto3
from botocore.exceptions import ClientError
from botocore.signers import RequestSigner
import yaml

_log_main   = logging.getLogger("ECR")
_log_ecs    = logging.getLogger("ECS")
_log_lambda = logging.getLogger("Lambda")
_log_eks    = logging.getLogger("EKS")


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
    platform: str | None = None             # set only for index children
    children: list["Image"] | None = None   # set only for indexes

    @property
    def is_index(self) -> bool:
        return self.children is not None

    @property
    def total_size(self) -> int:
        return self.size_bytes + sum(c.size_bytes for c in (self.children or []))


# ── ECR fetching ───────────────────────────────────────────────────────────────

def fetch_repository(ecr, repository: str) -> list[Image]:

    """
    Fetch all images, resolving index → child relationships.
    Returns top-level images only; children are nested under their parent Image.
    """

    raw = []
    for page in ecr.get_paginator("describe_images").paginate(repositoryName=repository):
        raw.extend(page["imageDetails"])

    raw.sort(key=lambda x: x.get("imagePushedAt", datetime.min.replace(tzinfo=timezone.utc)))

    # Resolve children for each image index
    index_children: dict[str, list[dict]] = {}
    for img in raw:
        if img.get("imageManifestMediaType") not in INDEX_MEDIA_TYPES:
            continue
        digest = img["imageDigest"]
        resp = ecr.batch_get_image(
            repositoryName=repository,
            imageIds=[{"imageDigest": digest}],
            acceptedMediaTypes=list(INDEX_MEDIA_TYPES),
        )
        pages = resp.get("images", [])
        if not pages:
            continue
        manifest = json.loads(pages[0]["imageManifest"])
        children = []
        for entry in manifest.get("manifests", []):
            plat = entry.get("platform", {})
            arch = plat.get("architecture", "?")
            variant = plat.get("variant", "")
            os_ = plat.get("os", "?")
            platform = f"{os_}/{arch}" + (f"/{variant}" if variant else "")
            children.append({"digest": entry["digest"], "platform": platform})
        index_children[digest] = children

    child_digests = {c["digest"] for kids in index_children.values() for c in kids}
    by_digest = {img["imageDigest"]: img for img in raw}

    images = []
    for r in raw:
        digest = r["imageDigest"]
        if digest in child_digests:
            continue

        children = None
        if digest in index_children:
            children = []
            for c in index_children[digest]:
                raw_child = by_digest.get(c["digest"])
                if raw_child is None:
                    continue
                children.append(Image(
                    digest=c["digest"],
                    tags=sorted(raw_child.get("imageTags", [])),
                    pushed_at=raw_child.get("imagePushedAt"),
                    last_pull=raw_child.get("lastRecordedPullTime"),
                    size_bytes=raw_child.get("imageSizeInBytes", 0),
                    platform=c["platform"],
                ))

        images.append(Image(
            digest=digest,
            tags=sorted(r.get("imageTags", [])),
            pushed_at=r.get("imagePushedAt"),
            last_pull=r.get("lastRecordedPullTime"),
            size_bytes=r.get("imageSizeInBytes", 0),
            media_type=r.get("imageManifestMediaType"),
            children=children,
        ))

    return images


def list_all_repositories(ecr) -> list[str]:
    """Return all repository names in the registry (sorted)."""
    repos: list[str] = []
    for page in ecr.get_paginator("describe_repositories").paginate():
        repos.extend(r["repositoryName"] for r in page["repositories"])
    return sorted(repos)


# ── deletion helpers ───────────────────────────────────────────────────────────

def find_candidates(images: list[Image], older_than_days: int) -> list[Image]:
    cutoff = datetime.now(timezone.utc) - timedelta(days=older_than_days)
    return [img for img in images if img.last_pull is None or img.last_pull < cutoff]


def deletion_digests(candidates: list[Image], all_images: list[Image]) -> list[str]:

    """
    Index candidates expand to include their children, but a child manifest is only
    emitted when every parent index that references it is also being deleted.

    ECR is content-addressed: two indexes can share the same child manifest by digest.
    Deleting a shared child while a non-candidate parent still references it would
    break that parent.
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


def execute_delete(ecr, repository: str, digests: list[str]) -> None:
    resp = ecr.batch_delete_image(
        repositoryName=repository,
        imageIds=[{"imageDigest": d} for d in digests],
    )
    print(f"Deleted: {len(resp.get('imageIds', []))} digest(s)")
    for f in resp.get("failures", []):
        img_id = f.get("imageId", {})
        print(f"  FAILED {img_id.get('imageDigest', '?')[:19]} — {f['failureCode']}: {f['failureReason']}")


def execute_archive(ecr, repository: str, digests: list[str]) -> None:
    # No batch equivalent for update_image_storage_class — one call per digest.
    succeeded = 0
    for digest in digests:
        resp = ecr.update_image_storage_class(
            repositoryName=repository,
            imageId={"imageDigest": digest},
            targetStorageClass="ARCHIVE",
        )
        status = resp.get("imageStatus", "?")
        if status in ("ARCHIVED", "ACTIVATING"):
            succeeded += 1
        else:
            print(f"  UNEXPECTED STATUS {digest[:19]} — {status}")
    print(f"Archived: {succeeded}/{len(digests)} digest(s)")


# ── consumer protection ───────────────────────────────────────────────────────

def _collect_ecr_digest(ecr, image: str, in_use: dict[str, set[str]]) -> bool:

    """
    Parse an ECR image URI and record (repo, digest) into in_use.

    Returns True if a new digest was recorded; False otherwise (no match, malformed URI,
    or duplicate digest already in the set).

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
    Return all ECR digests actively referenced by ECS task definitions, grouped by repo.

    Checks the active task definition of every service in every cluster.
    Running tasks pinned to older task definition revisions are NOT protected.
    """

    _log_ecs.info("Scanning clusters...")
    task_def_arns: set[str] = set()
    for page in ecs.get_paginator("list_clusters").paginate():
        for cluster in page["clusterArns"]:
            arns: list[str] = []
            for p in ecs.get_paginator("list_services").paginate(cluster=cluster):
                arns.extend(p["serviceArns"])
            cluster_task_defs: set[str] = set()
            for i in range(0, len(arns), 10):  # describe_services max 10 per call
                for svc in ecs.describe_services(cluster=cluster, services=arns[i:i+10])["services"]:
                    if svc.get("taskDefinition"):
                        cluster_task_defs.add(svc["taskDefinition"])
            task_def_arns |= cluster_task_defs
            _log_ecs.info("  %s: %d service(s), %d task def(s)", cluster.split("/")[-1], len(arns), len(cluster_task_defs))

    in_use: dict[str, set[str]] = {}
    for td_arn in task_def_arns:
        td = ecs.describe_task_definition(taskDefinition=td_arn)["taskDefinition"]
        parts = td_arn.split(":")
        td_short = f"{parts[-2].split('/')[-1]}:{parts[-1]}" if len(parts) >= 2 else td_arn
        for container in td.get("containerDefinitions", []):
            image = container.get("image", "")
            if _collect_ecr_digest(ecr, image, in_use):
                _log_ecs.info("  match: %s  (%s)", image, td_short)

    total = sum(len(v) for v in in_use.values())
    _log_ecs.info("%d digest(s) across %d repo(s)", total, len(in_use))
    return in_use


def fetch_lambda_digests(ecr, lambda_client) -> dict[str, set[str]]:

    """
    Return all ECR digests referenced by Lambda image functions, grouped by repo.

    Checks $LATEST configuration only. Published versions pointed to by aliases are
    not inspected — they would require an extra list_aliases + versioned get_function pass.
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
    _log_lambda.info("%d image function(s) scanned, %d digest(s) across %d repo(s)", fn_count, total, len(in_use))
    return in_use


def _eks_token(cluster_name: str, region: str, session) -> str:

    """
    Generate an EKS bearer token (equivalent to aws eks get-token).

    Uses a SigV4-presigned STS GetCallerIdentity URL — the standard EKS auth mechanism.
    """

    sts = session.client("sts", region_name=region)
    signer = RequestSigner(
        sts.meta.service_model.service_id,
        region, "sts", "v4",
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

    Queries /api/v1/pods on each cluster's Kubernetes API server. Private-endpoint
    clusters are only reachable from within the cluster's VPC — unreachable clusters
    are skipped with a stderr warning.
    Checks both status.containerStatuses[].imageID (resolved digest, set after pull)
    and spec.containers[].image (covers pending containers before imageID is populated).
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
            with urllib.request.urlopen(req, context=ctx) as resp:
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
                    _log_eks.info("    match (imageID): %s/%s -> %s", pod_name, cs.get("name", "?"), image_id)
            spec = pod.get("spec", {})
            for c in (spec.get("containers") or []) + (spec.get("initContainers") or []):
                image = c.get("image", "")
                if _collect_ecr_digest(ecr, image, in_use):
                    _log_eks.info("    match (spec):    %s/%s -> %s", pod_name, c.get("name", "?"), image)

        matched = sum(len(v) for v in in_use.values()) - before_cluster
        _log_eks.info("  %d pod(s), %d new digest(s)", len(pod_list.get("items", [])), matched)

    total = sum(len(v) for v in in_use.values())
    _log_eks.info("%d digest(s) across %d repo(s)", total, len(in_use))
    return in_use


def exclude_ecs_used(candidates: list[Image], in_use: set[str]) -> tuple[list[Image], list[Image]]:

    """
    Split candidates into (to_act_on, excluded_by_ecs).

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


# ── serialization ──────────────────────────────────────────────────────────────

def _serialize(obj):
    if isinstance(obj, datetime):
        return obj.isoformat()
    if isinstance(obj, list):
        return [_serialize(i) for i in obj]
    if dataclasses.is_dataclass(obj):
        return {k: _serialize(v) for k, v in vars(obj).items()}
    return obj

def listing_as_dict(per_repo: list[tuple[str, list[Image]]]) -> dict:
    repositories = []
    grand_count = 0
    grand_size = 0
    for repo, images in per_repo:
        total_size = sum(img.total_size for img in images)
        total_count = sum(1 + len(img.children or []) for img in images)
        repositories.append({
            "repository": repo,
            "total_images": total_count,
            "total_size_bytes": total_size,
            "images": [_serialize(img) for img in images],
        })
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


def action_plan_as_dict(per_repo: list[tuple[str, list[Image], list[Image], list[str]]], older_than_days: int, dry_run: bool, action: str) -> dict:
    repositories = []
    grand_candidates = 0
    grand_digests = 0
    grand_size = 0
    for repo, candidates, excluded, digests in per_repo:
        total_size = sum(img.total_size for img in candidates)
        repositories.append({
            "repository": repo,
            "total_candidates": len(candidates),
            "total_digests": len(digests),
            "total_size_bytes": total_size,
            "candidates": [_serialize(img) for img in candidates],
            "digests_to_delete": digests,
            "protected": [_serialize(img) for img in excluded],
        })
        grand_candidates += len(candidates)
        grand_digests += len(digests)
        grand_size += total_size
    return {
        "action": action,
        "dry_run": dry_run,
        "older_than_days": older_than_days,
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


# ── table renderers ────────────────────────────────────────────────────────────

def _render_repo_listing(images: list[Image], repository: str) -> None:
    TAG_W, PUSH_W, PULL_W, SIZE_W = 45, 12, 12, 10
    header = f"{'TAGS':<{TAG_W}}  {'PUSHED':<{PUSH_W}}  {'LAST PULL':<{PULL_W}}  {'SIZE':<{SIZE_W}}  DIGEST"
    sep = "-" * len(header)
    total_size = sum(img.total_size for img in images)
    total_count = sum(1 + len(img.children or []) for img in images)

    def _row(tag_field: str, pushed_at: datetime | None, last_pull: datetime | None, size_bytes: int, digest: str) -> None:
        if len(tag_field) > TAG_W:
            tag_field = tag_field[: TAG_W - 1] + "…"
        print(
            f"{tag_field:<{TAG_W}}  {_age(pushed_at):<{PUSH_W}}  {_age(last_pull):<{PULL_W}}"
            f"  {_size(size_bytes):<{SIZE_W}}  {digest[:19]}"
        )

    print(f"\nRepository: {repository}  ({total_count} images)\n")
    print(header)
    print(sep)
    for img in images:
        tags = ", ".join(img.tags) or "[untagged]"
        _row(f"{tags} [index]" if img.is_index else tags, img.pushed_at, img.last_pull, img.size_bytes, img.digest)
        for i, child in enumerate(img.children or []):
            tree = "└─" if i == len(img.children) - 1 else "├─"
            child_tags = ", ".join(child.tags) or "[untagged]"
            _row(f"  {tree} {child.platform:<16}{child_tags}", child.pushed_at, child.last_pull, child.size_bytes, child.digest)
    print(sep)
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


def _render_repo_action(repository: str, candidates: list[Image], digests: list[str], older_than_days: int, dry_run: bool, action: str, excluded: list[Image]) -> None:
    VERBS   = {
        "delete":  ("DELETE",  "Would delete",  "Deleting"),
        "archive": ("ARCHIVE", "Would archive", "Archiving")
    }
    SYMBOLS = {"delete": "[-]", "archive": "[~]"}
    label_mode, verb_dry, verb_live = VERBS[action]
    sym = SYMBOLS[action]
    label = f"DRY RUN ({label_mode})" if dry_run else label_mode
    excluded = excluded or []
    safe_set = set(digests)
    if not candidates and not excluded:
        print(f"\n[{label}] No images match criteria (not pulled in {older_than_days}+ days)\n")
        return
    if not candidates:
        print(f"\n[{label}] No images match criteria (not pulled in {older_than_days}+ days)\n")
    else:
        total_size = sum(img.total_size for img in candidates)
        verb = verb_dry if dry_run else verb_live
        n_children = len(digests) - len(candidates)
        unique_children = {c.digest for img in candidates for c in (img.children or [])}
        retained = len(unique_children) - n_children
        child_note = f" + {n_children} child(ren)" if n_children else ""
        retained_note = f" — {retained} shared child(ren) retained" if retained else ""
        print(f"\n[{label}] {verb} {len(candidates)} image(s){child_note} = {len(digests)} digest(s), {_size(total_size)}{retained_note}\n")
        for img in candidates:
            tags = ", ".join(img.tags) or "[untagged]"
            reason = "never pulled" if img.last_pull is None else f"last pull: {_age(img.last_pull)}"
            n = len(img.children) if img.children else 0
            suffix = f" [index, {n} child(ren)]" if img.is_index else ""
            print(f"  {sym} {tags}{suffix}  —  {reason}  —  {_size(img.size_bytes)}  —  {img.digest[:19]}")
            for i, child in enumerate(img.children or []):
                tree = "└─" if i == len(img.children) - 1 else "├─"
                if child.digest in safe_set:
                    print(f"    {tree} {sym} {child.platform:<16}  {_size(child.size_bytes):<10}  {child.digest[:19]}")
                else:
                    print(f"    {tree} [=] {child.platform:<16}  {_size(child.size_bytes):<10}  {child.digest[:19]}  (shared, retained)")
    if excluded:
        print(f"\n[PROTECTED] {len(excluded)} image(s) excluded — in use by ECS, Lambda, or EKS\n")
        for img in excluded:
            tags = ", ".join(img.tags) or "[untagged]"
            n = len(img.children) if img.children else 0
            suffix = f" [index, {n} child(ren)]" if img.is_index else ""
            print(f"  [=] {tags}{suffix}  —  {_size(img.total_size)}  —  {img.digest[:19]}")
            for i, child in enumerate(img.children or []):
                tree = "└─" if i == len(img.children) - 1 else "├─"
                print(f"    {tree} [=] {child.platform:<16}  {_size(child.size_bytes):<10}  {child.digest[:19]}")
    print()


def render_action(per_repo: list[tuple[str, list[Image], list[Image], list[str]]], older_than_days: int, dry_run: bool, action: str) -> None:
    grand_candidates = 0
    grand_digests = 0
    grand_size = 0
    for repo, candidates, excluded, digests in per_repo:
        print(f"\n══ Repository: {repo} ══")
        _render_repo_action(repo, candidates, digests, older_than_days, dry_run, action, excluded)
        grand_candidates += len(candidates)
        grand_digests += len(digests)
        grand_size += sum(img.total_size for img in candidates)
    if len(per_repo) > 1:
        verb = "Would" if dry_run else ""
        print(f"=== Summary: {len(per_repo)} repos, {verb} {action} {grand_candidates} image(s) = {grand_digests} digest(s), {_size(grand_size)} ===\n")


# ── formatting utils ───────────────────────────────────────────────────────────

def _age(dt: datetime | None) -> str:
    if dt is None:
        return "never"
    days = (datetime.now(timezone.utc) - dt).days
    if days == 0:
        return "today"
    return f"1d ago" if days == 1 else f"{days}d ago"


def _size(size_bytes: int) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if size_bytes < 1024:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024
    return f"{size_bytes:.1f} TB"


# ── main ───────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="List and optionally delete/archive images in ECR repositories")
    parser.add_argument("repositories", nargs="*", default=[],
                        help="repository names; omit and pass --all to process all repos")
    parser.add_argument("--all", action="store_true", dest="all_repos",
                        help="process all repositories in the registry")
    parser.add_argument("--region", default="eu-west-1")
    parser.add_argument("--profile")
    parser.add_argument("--output", "-o", choices=["table", "json", "yaml"], default="table")
    action_grp = parser.add_mutually_exclusive_group()
    action_grp.add_argument("--delete", "-d", action="store_true")
    action_grp.add_argument("--archive", "-a", action="store_true")
    parser.add_argument("--older-than", type=int, default=30, metavar="DAYS")
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--max-workers", type=int, default=10, metavar="N",
                        help="parallel workers for per-repo fetching (default: 10)")
    parser.add_argument("--check-ecs", action="store_true", dest="check_ecs",
                        help="exclude images in use by active ECS task definitions")
    parser.add_argument("--check-lambda", action="store_true", dest="check_lambda",
                        help="exclude images in use by Lambda functions (checks $LATEST)")
    parser.add_argument("--check-eks", action="store_true", dest="check_eks_flag",
                        help="exclude images in use by pods across all EKS clusters (requires endpoint access)")
    parser.add_argument("--verbose", "-v", action="store_true",
                        help="print scanning progress and matches to stderr")
    args = parser.parse_args()

    if bool(args.repositories) == bool(args.all_repos):
        parser.error("specify either <repository>(s) positional or --all (not both)")

    logging.basicConfig(
        level=logging.INFO if args.verbose else logging.WARNING,
        stream=sys.stderr,
        format="[%(name)s] %(message)s",
    )
    logging.getLogger("botocore").setLevel(logging.WARNING)

    session = boto3.Session(profile_name=args.profile, region_name=args.region)
    ecr = session.client("ecr")

    # Resolve target repos
    if args.all_repos:
        target_repos = list_all_repositories(ecr)
        _log_main.info("Processing all %d repositories", len(target_repos))
    else:
        target_repos = args.repositories

    # Run consumer checks ONCE (across the whole registry, not per-repo)
    in_use_by_repo: dict[str, set[str]] = {}
    def _merge(other: dict[str, set[str]]) -> None:
        for r, digests in other.items():
            in_use_by_repo.setdefault(r, set()).update(digests)
    if args.check_ecs:
        _merge(fetch_ecs_digests(ecr, session.client("ecs")))
    if args.check_lambda:
        _merge(fetch_lambda_digests(ecr, session.client("lambda")))
    if args.check_eks_flag:
        _merge(fetch_eks_digests(ecr, session.client("eks"), args.region, session))

    # Parallel per-repo fetch
    _log_main.info("Fetching %d repo(s) with %d worker(s)...", len(target_repos), args.max_workers)
    fetched: dict[str, list[Image]] = {}
    with ThreadPoolExecutor(max_workers=args.max_workers) as ex:
        futures = {ex.submit(fetch_repository, ecr, repo): repo for repo in target_repos}
        for fut in as_completed(futures):
            repo = futures[fut]
            try:
                fetched[repo] = fut.result()
            except Exception as e:
                _log_main.warning("failed to fetch %s: %s", repo, e)
                fetched[repo] = []

    # Preserve input order
    ordered_listing: list[tuple[str, list[Image]]] = [(r, fetched[r]) for r in target_repos if r in fetched]

    action = "delete" if args.delete else "archive" if args.archive else None

    if action:
        ordered_action: list[tuple[str, list[Image], list[Image], list[str]]] = []
        for repo, images in ordered_listing:
            candidates = find_candidates(images, args.older_than)
            in_use = in_use_by_repo.get(repo, set())
            if in_use:
                candidates, excluded = exclude_ecs_used(candidates, in_use)
            else:
                excluded = []
            digests = deletion_digests(candidates, images)
            ordered_action.append((repo, candidates, excluded, digests))

        dry_run = not args.execute
        if args.output == "table":
            render_action(ordered_action, args.older_than, dry_run, action)
        else:
            emit(action_plan_as_dict(ordered_action, args.older_than, dry_run, action), args.output)

        if args.execute:
            for repo, candidates, _, digests in ordered_action:
                if not candidates:
                    continue
                if action == "delete":
                    execute_delete(ecr, repo, digests)
                else:
                    execute_archive(ecr, repo, digests)
    else:
        if args.output == "table":
            render_listing(ordered_listing)
        else:
            emit(listing_as_dict(ordered_listing), args.output)


if __name__ == "__main__":
    main()
