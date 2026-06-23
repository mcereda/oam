# Elastic Container Registry

1. [TL;DR](#tldr)
1. [Image scanning](#image-scanning)
1. [Lifecycle policies](#lifecycle-policies)
   1. [Archive tier constraints](#archive-tier-constraints)
   1. [Middling with multi-arch images](#middling-with-multi-arch-images)
1. [Pull through cache feature](#pull-through-cache-feature)
1. [Cleaning up old images](#cleaning-up-old-images)
1. [Troubleshooting](#troubleshooting)
   1. [Docker pull errors with `no basic auth credentials`](#docker-pull-errors-with-no-basic-auth-credentials)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Children images of an image index _can_ carry tags.

```sh
# List and get information about the repositories in ECRs.
aws ecr describe-repositories
aws ecr describe-repositories --repository-names 'docker-tools/image-builder'
aws ecr describe-repositories --registry-id '123456789012' --query 'repositories[].repositoryName'

# Create repositories.
aws ecr create-repository --repository-name 'docker-tools/image-builder'

# Delete repositories.
aws ecr delete-repository --repository-name 'banana/slug'

# List images in ECRs.
aws ecr list-images --repository-name 'repository'
aws ecr list-images --registry-id '123456789012' --repository-name 'my-image'

# Check images exist in the ECR.
[[ \
  $(
    aws ecr list-images --repository-name 'repository' \
      --query "length(imageIds[?@.imageTag=='latest'])" --output 'text' \
  ) -le 0 \
]] && echo "image 'repository:latest' exists" || echo "image 'repository:latest' does not exist"


# Use ECRs as Docker registries.
aws ecr get-login-password \
| docker login --username 'AWS' --password-stdin 'aws_account_id.dkr.ecr.region.amazonaws.com'

# Pull images from ECRs.
docker pull 'aws_account_id.dkr.ecr.region.amazonaws.com/repository_name/image_name:tag'


# List and show pull through cache rules.
aws ecr describe-pull-through-cache-rules
aws ecr describe-pull-through-cache-rules \
  --registry-id '123456789012' --ecr-repository-prefixes 'ecr-public' 'quay'

# Create pull through cache rules.
aws ecr create-pull-through-cache-rule \
  --registry-id '123456789012' --ecr-repository-prefix 'prefix' \
  --upstream-registry 'docker-hub' --upstream-registry-url 'registry-1.docker.io' \
  --credential-arn "$( \
    aws secretsmanager describe-secret --secret-id 'ecr-pullthroughcache/docker-hub' \
      --query 'ARN' --output 'text' \
  )"

# Validate pull through cache rules.
aws ecr validate-pull-through-cache-rule \
  --registry-id '123456789012' --ecr-repository-prefix 'prefix'

# Pull images from cache repositories.
docker pull 'aws_account_id.dkr.ecr.region.amazonaws.com/prefix/repository_name/image_name:tag'
docker pull '123456789012.dkr.ecr.us-east-2.amazonaws.com/ecr-public/repository_name/image_name:tag'
docker pull '123456789012.dkr.ecr.eu-west-1.amazonaws.com/quay/argoproj/argocd:v2.10.0'
# DockerHub cache repositories require the full path.
# E.g., 'library/alpine' instead of just 'alpine'.
docker pull '123456789012.dkr.ecr.eu-south-1.amazonaws.com/docker-hub/library/nginx:perl'
docker pull '123456789012.dkr.ecr.us-west-2.amazonaws.com/docker-hub/grafana/grafana'

# List lifecycle policies for a repository.
aws ecr get-lifecycle-policy --repository-name 'repository'

# Preview what a lifecycle policy would expire/archive (dry-run).
aws ecr start-lifecycle-policy-preview --repository-name 'repository' \
  --lifecycle-policy-text 'file://policy.json'
aws ecr get-lifecycle-policy-preview --repository-name 'repository'

# Apply a lifecycle policy to a repository.
aws ecr put-lifecycle-policy --repository-name 'repository' \
  --lifecycle-policy-text 'file://policy.json'

# List repository creation templates.
aws ecr describe-repository-creation-templates

# Check what ECR Basic Scanning technology is used by the account.
aws ecr get-account-setting --name 'BASIC_SCAN_TYPE_VERSION' --query 'value' --output 'text'
# Change it.
aws ecr put-account-setting --name 'BASIC_SCAN_TYPE_VERSION' --value 'AWS_NATIVE'
aws ecr put-account-setting --name 'BASIC_SCAN_TYPE_VERSION' --value 'CLAIR'
```

```sh
aws ecr describe-repositories --repository-names 'docker-tools/image-builder' \
|| aws ecr create-repository --repository-name 'docker-tools/image-builder'
```

Constraints:

| What            | Type   | Constraints                                                                                        | Reference                                                                                             |
| --------------- | ------ | -------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Image tag       | String | 1 <= length <= 300                                                                                 | [ImageIdentifier](https://docs.aws.amazon.com/AmazonECR/latest/APIReference/API_ImageIdentifier.html) |
| Repository name | String | 2 <= length <= 256<br/>Must match `(?:[a-z0-9]+(?:[._-][a-z0-9]+)*/)*[a-z0-9]+(?:[._-][a-z0-9]+)*` | [Image](https://docs.aws.amazon.com/AmazonECR/latest/APIReference/API_Image.html)                     |

Lambda functions do **not** pull from ECR on cold starts. After the initial deployment, the service breaks the image
into chunks and stores them in S3, then uses them from a tiered internal cache for subsequent cold starts.<br/>
Images actively serving Lambda invocations can have a `lastRecordedPullTime` value that has been stale for years.

## Image scanning

ECR can scan images in two ways:

- **Basic** scanning is free, runs on push (or manually), and covers OS-package CVEs only.
- **Enhanced** scanning is paid through its use in Amazon Inspector, runs on push **and** continuously re-scans any time
  Inspector's CVE database updates, and covers both OS packages and programming-language packages.

| Feature             | Basic                                   | Enhanced                                 |
| ------------------- | --------------------------------------- | ---------------------------------------- |
| Cost                | **Free** (no ECR charge)                | **Paid** via Amazon Inspector            |
| Coverage            | CVEs for OS packages only               | OS and programming language packages     |
| Trigger             | On-push or manual                       | On-push AND continuous re-scan           |
| Configuration scope | Per-repo (deprecated) or registry-level | Registry-level only                      |
| Billing source      | None (Amazon ECR)                       | Amazon Inspector (per-scan + per-rescan) |

Pulumi's `imageScanningConfiguration.scanOnPush` field on `aws.ecr.Repository` resources enables basic scanning
**per repository**. The cost for this is zero.

The repository-level scan on push feature is **deprecated** in favour of registry-level scan configurations. Existing
per-repository configurations continue to work, but consider planning a migration when convenient.

Enhanced scanning is configured at the **registry level only** as a single switch for all repos in the account, or
selecting a subset of them via filters. Cost is per initial scan, plus per rescan as the CVE database updates, plus per
CI/CD scan if integrated with Jenkins, TeamCity, or similar.

> [!caution]
> Switching between basic and enhanced **loses** previous scan findings. The data isn't shared between modes. Switching
> back **restores** the original mode's findings.

## Lifecycle policies

One can use lifecycle rules **per repository** to delete or archive untagged images, images not pulled in a while,
and/or combinations of those and other settings.

ECR offers 2 **time-based** count types:

- `sinceImagePushed`: days since an image was pushed.<br/>
  Supports both `expire` (delete) and `transition` (archive) actions.
- `sinceImagePulled`: days since the image was last pulled.<br/>
  Only supports `transition` (archive), **not** `expire`. Falls back to `pushed_at_time` if never pulled, or
  `last_activated_at` if restored from archive but not pulled since.

One _can_ delete images based on pull activity by just directly setting them to `expire` with a `sinceImagePushed`
rule.<br/>
It would be best practice to do that in 2 steps, though:

1. `transition` unused images to archival storage with a `sinceImagePulled` rule.
1. `expire` them in the archive after some time with an additional `sinceImageTransitioned` rule.

When multiple rules exist, the `rulePriority` field (a _lower_ value maps to _higher_ priority) controls their
precedence. All rules are evaluated **simultaneously**, then applied by priority. An image is expired or archived by
exactly one or zero rules.

Images matching lifecycle policy criteria are processed within **24 hours**. Use
[`StartLifecyclePolicyPreview`][StartLifecyclePolicyPreview] to dry-run before applying.

[Repository creation templates] can apply default lifecycle policies to repositories created via pull-through cache,
create-on-push, or replication. The `ROOT` prefix acts as a catch-all. These do **not** apply to repositories created
manually.

### Archive tier constraints

Archival **below 150 TB** is a pricing trap. It costs the same rate as the standard tier ($0.10/GB/month in Ireland),
but loses direct pull access, retrieval costs an additional fee of $0.03/GB, and locks into a 90-day minimum.

When `sinceImagePulled` → `transition` moves images to archival storage, several non-obvious constraints apply:

- Archived images are billed with a **90-day minimum storage duration**.

  Lifecycle policies **cannot** be configured to delete archived images **before** 90 days after transition. AWS just
  rejects shorter values when one submits the policy with _You cannot configure lifecycle policies that delete images
  that have been in archive for less than 90 days".<br/>
  Manual `batch-delete-image` still works, but AWS charges for the 90-day minimum regardless.

- Archived images **fail with `404` on pull**.

  Once archived, images **cannot be pulled** until **explicitly** restored. ECR storage is different from S3's Glacier
  and its "slower retrieval".<br/>
  Restoring archived images typically takes **20 minutes** or less; the image's status reads `ACTIVATING` during that
  time frame.

- ECR does **not** automatically restore an archived image when a pull returns `404`.

  Possible workarounds:

  - **Re-push** the same image.<br/>
    This immediately restores the image and does not require waiting, but does requires the image to be available
    locally for push.
  - **Manual restoration** via API.<br/>
    Run `aws ecr update-image-storage-class --repository-name 'some/repo' --image-id 'imageDigest=<digest>'
    --target-storage-class STANDARD`, then wait up to 20 minutes.
  - Detect the failed `BatchGetImage` call on CloudTrail, and leverage EventBridge to trigger a Lambda to restore the
    image. Still requires a 20-minute wait; the deployer also needs retry logic.

- For images archived and then restored, but **not** yet pulled since restoration, `sinceImagePulled` uses
  `last_activated_at` (the restore timestamp) rather than the original `last_recorded_pulltime`.<br/>
  A restored image gets a fresh hot window before being re-archived.

### Middling with multi-arch images

AWS documents an `ImageReferencedByManifestList` guard that _should_™ prevent lifecycle policies from expiring or
archiving child manifests while their parent manifest list exists. In practice, this guard proved **unreliable**,
particularly for pull-through cache repositories.

The guard fires **only** at **execution** time. The lifecycle evaluator might mark untagged children as candidates
**without** checking manifest-list relationships.<br/>
The guard may catch some of those relationships at deletion time, but race conditions in the execution engine cause it
to misfire inconsistently. See [containers-roadmap#2613](https://github.com/aws/containers-roadmap/issues/2613).

> [!caution]
> Consider lifecycle rules with `tagStatus: untagged` as **unsafe** for repositories containing multi-architecture
> images, regardless of the documented protection. A `tagStatus: untagged` rule with a short expiry on a pull-through
> cache repository deleted platform-specific children of a live production multi-arch image, breaking deployments.
>
> Custom cleanup scripts must build a parent-child map **explicitly** before making deletion decisions. See
> [Cleaning up old images].

## Pull through cache feature

Refer [Troubleshooting pull through cache issues in Amazon ECR].

> **Note:** when requesting an image for the first time using the pull through cache, the ECR tries creating a new
> repository for that image.<br>
> This might™ introduce a small latency and be cause of pull failures. Pulling that (not-yet)cached image from an
> interactive shell session worked flawlessly.

Docker Hub's official images (e.g. `alpine`, `nginx`, `debian`) use an implicit `library/` namespace that the Docker CLI
adds transparently (`docker pull alpine` resolves to `docker.io/library/alpine`). ECR's pull-through cache does
**not**.<br/>
Always use the **full** path to pull official images from a docker hub pull-through cache
(`<prefix>/library/<image>:<tag>`). Omitting `library/` from the ECR pull URL for such images returns a
**403 Forbidden**, not a descriptive error.

The user or role pulling the image must be granted the `ecr:BatchImportUpstreamImage` permission for the feature to
work as expected.<br/>
The service intercepts the pull request to check the upstream. Without this permission, ECR returns _not found_ (and
not _access denied_) **intentionally**.

> [!important]
> The `ecr:BatchImportUpstreamImage` permission gates the **upstream fetch**, but **allows** reading the cached image in
> the repository.<br/>
> Images **already cached** only require the normal pull permissions (`ecr:GetAuthorizationToken`, `ecr:BatchGetImage`,
> `ecr:GetDownloadUrlForLayer`, `ecr:BatchCheckLayerAvailability`). `ecr:BatchImportUpstreamImage` is only checked on a
> **cache miss**.

When the cache repository doesn't exist yet under the prefix, the entity pulling the image either needs to create the
repository first, or it needs `ecr:CreateRepository`. This permission is **not** included in the standard
`AmazonEC2ContainerRegistryReadOnly` and `AmazonECSTaskExecutionRolePolicy` AWS-managed policies.<br/>
[Repository creation templates] only describe what the new repository should look like, and **do** still require the
puller to create the repository. Similarly, ECS services pulling from cache repositories need an additional policy
granting both actions (possibly scoped to the cache prefix).

AWS has since published `AmazonEC2ContainerRegistryPullOnly`, which includes `ecr:BatchImportUpstreamImage` alongside
the plain pull actions.<br/>
This is now the recommended least-privilege policy for node roles, and EKS Auto Mode uses it by default.
`ecr:CreateRepository` remains **absent** from both managed policies, and upstream paths not yet in the cache still
require it to be granted in an additional policy.

> [!tip]
> Scope extra permissions to the cache namespace only.<br/>
> **Never** grant `BatchImportUpstreamImage` and `CreateRepository` on `Resource: "*"`.
>
> ```ts
> new aws.iam.RolePolicy(
>   'someRole-allowPopulatingTheEcrCache',
>   {
>     name: 'AllowPopulatingTheEcrCache',
>     role: nodeRole.name,
>     policy: pulumi.jsonStringify({
>       Version: '2012-10-17',
>       Statement: [
>         {
>           Effect: 'Allow',
>           Action: [
>             'ecr:BatchImportUpstreamImage',
>             'ecr:CreateRepository',
>           ],
>           Resource: 'arn:aws:ecr:eu-west-1:012345678901:repository/some-prefix/*',
>         },
>       ],
>     }),
>   },
> );
> ```

> [!warning]
> For EKS specifically, the **kubelet running on the node** is the one pulling images from ECRs.<br/>
> The kubelet uses the **node**'s instance-profile role. It does **not** consult pod-level roles (Pod Identity, IRSA)
> when pulling images. Instead, they only kick in once the container is running and the SDK reaches for credentials. A
> pod can be perfectly configured with Pod Identity and still hit `ImagePullBackOff` if the node role lacks the relevant
> ECR permissions.

## Cleaning up old images

When writing cleanup scripts against multi-arch images, pull-through cache repositories, or anything that combines ECR
with ECS/Lambda/EKS consumer-side lookups, the following issues might arise:

- Pull timestamps for image indices are **not** propagated to their children.

  <details style='padding: 0 0 1rem 1rem'>

  When pulling a multi-arch image (manifest list / OCI image index), ECR records the `lastRecordedPullTime` only on the
  **index**. The individual platform manifests (children) keep their own previous `lastRecordedPullTime`. This value
  is often `null` if they were never pulled directly.

  A naive cleanup rule like `last_pull == null` will incorrectly flag child manifests as safe to delete, even if they
  are actively used through the parent index. Treat a child as in-use if its parent index has a recent
  `lastRecordedPullTime` value, regardless of the child's own timestamp.

  </details>

- Children of a manifest index are usually **not** tagged, but _can_ carry a tag.

  <details style='padding: 0 0 1rem 1rem'>

  The `describe_images` API returns `imageTags` on every `ImageDetail` regardless of media type.

  ECR stores platform-specific manifests (children) as untagged images by default. The only way to tell whether an
  untagged image is a standalone orphan or a child referenced by a live index is to:

  1. Identify indices via `imageManifestMediaType` (`application/vnd.docker.distribution.manifest.list.v2+json` for
     Docker, `application/vnd.oci.image.index.v1+json` for OCI).
  1. Call `batch_get_image` on each index to get the manifest's JSON.
  1. Extract the children's digests.
  1. Build a `child_digest → parent_digest` map **before** making any deletion decisions.

  Lifecycle policies do **not** understand parent-child relationships, and **will** delete children images orphaning
  their index.

  </details>

- Indices can share child manifests across the repository.

  <details style='padding: 0 0 1rem 1rem'>

  Two **distinct** image indices within the same repository can reference the **same** child manifest by digest. This
  happens normally when the upstream registry pushes the same manifest under multiple index tags. It is common with
  pull-through cache repositories holding multi-arch images that share platform layers across releases.

  Cleanup methods like "expand index → delete all children" are unsafe when children are shared. Deleting one stale
  index can break another live index that shares its children. Before deleting the child manifest of an index, verify
  that **every** parent index referencing that child is also being deleted. If any parent survives, the shared child
  must survive too. This is the OCI-registry parallel to reference counting.

  </details>

- `batch_get_image` requires `acceptedMediaTypes` for indices.

  <details style='padding: 0 0 1rem 1rem'>

  Without setting `acceptedMediaTypes` to the manifest-list types, ECR resolves the index to only the single platform
  manifest matching the caller's architecture, and silently returns _that child's_ manifest instead. The returned
  `imageId` will be the **child**'s digest, **not** the index's one.

  ```python
  index = ecr.batch_get_image(
      repositoryName=repo,
      imageIds=[{"imageDigest": index_digest}],
      acceptedMediaTypes=[
          "application/vnd.docker.distribution.manifest.list.v2+json",
          "application/vnd.oci.image.index.v1+json",
      ],
  )
  ```

  </details>

- The `pushed_at` value for pull-through cache is "when it has been first cached", not that image's effective age.

  <details style='padding: 0 0 1rem 1rem'>

  In pull-through cache repositories, `imagePushedAt` reflects when the ECR first stored that digest, **not** when the
  upstream image was effectively built or tagged. If a new index version references a platform manifest that ECR already
  has cached (same digest, different tag), the child's `pushed_at` stays at the original cache date.

  Use the parent index's `pushed_at` as the authoritative age for a multi-arch image, not the children's.

  </details>

- `update_image_storage_class` has no _batch_ equivalent.

  <details style='padding: 0 0 1rem 1rem'>

  `batch_delete_image` accepts up to 100 digests per call. `update_image_storage_class` accepts **only one** image at a
  time. To archive multiple images, loop and call once per digest. The response includes `imageStatus`, which will
  be `ARCHIVED` or `ACTIVATING`. It is **not** an immediate transition.

  </details>

- ECS task definitions might pin images as `<repository>:<tag>@<digest>`.

  <details style='padding: 0 0 1rem 1rem'>

  Strip the `:tag` suffix after splitting on `@`:

  ```python
  if "@" in rest:
      ref, digest = rest.split("@", 1)
      repo_part = ref.rsplit(":", 1)[0] if ":" in ref else ref
  ```

  </details>

- Lambda functions based on containers return both `ResolvedImageUri` and `ImageUri`.

  <details style='padding: 0 0 1rem 1rem'>

  `get_function()` returns two image URI fields in `Code`:

  - `ImageUri`, which is what the user specified  and might be a tag reference like `repo:latest`.
  - `ResolvedImageUri`, which is the image's SHA256 form, resolved at deploy time (always `repo@sha256:...`).

  For digest matching, use `ResolvedImageUri`. It is always in digest form and avoids a secondary `describe_images`
  lookup.<br/>
  `list_functions()` only returns the `$LATEST` configuration; functions that route traffic via aliases to published
  versions reference a different image from `$LATEST`. Cover those with a `list_aliases()` plus a versioned
  `get_function(FunctionName=fn, Qualifier=alias)` pass per function. Filter by `PackageType: Image` before calling
  `get_function` to avoid unnecessary API calls for Zip-based functions.

  </details>

- EKS pod image resolution requires both `imageID` and `spec.containers[].image`.

  <details style='padding: 0 0 1rem 1rem'>

  When querying running pods from the Kubernetes API, two fields carry image information and both are needed:

  - `status.containerStatuses[].imageID` is the fully resolved digest, set after the image is pulled.<br/>
  This field is missing on pending or initializing containers.
  - `spec.containers[].image` is what the manifest declared. This is always present, but may be a tag reference rather
  than a digest.

  With the legacy Docker runtime, `imageID` is prefixed with `docker-pullable://`. The Containerd runtime omits that
  prefix. Strip it before parsing:

  ```python
  image = image.removeprefix("docker-pullable://")
  ```

  </details>

- `lastRecordedPullTime` is updated at most once every 24 hours.

  <details style='padding: 0 0 1rem 1rem'>

  ECR rate-limits `lastRecordedPullTime` advances to at most one update per image per 24 hours. A timestamp of
  "1 day ago" means the image was pulled at least once in the last 24 hours, but not that it was pulled _exactly_ once
  at that time. ECR does not update the timestamp without an actual pull.

  This affects threshold decisions during cleanups, since an image pulled 23 hours ago and one pulled 25 hours ago may
  appear indistinguishable from this field alone.

  </details>

- `batch_get_image` on an index manifest updates its `lastRecordedPullTime`.

  <details style='padding: 0 0 1rem 1rem'>

  Calling `batch_get_image` on an index to inspect its children (e.g. to build the parent-child map) counts as a pull,
  and updates `lastRecordedPullTime` on that index. A cleanup script that iterates all indices to resolve their children
  will set every index's timestamp to roughly "one run-interval ago".<br/>
  This makes the last pull's time an unreliable signal for indices.

  If **all** index images in a repository show `lastRecordedPullTime` with sequential gaps within a couple of seconds in
  the order they would be iterated, the timestamps were likely updated by an inspection, not by real pulls.

  Child manifests are **not** updated by `batch_get_image` for their parent, so they preserve their pull history.
  When using the last pull time as a cleanup signal, prefer child timestamps over the index's, or actively check
  consumers (e.g., ECS, EKS, lambdas).

  </details>

- `batch_delete_image` accepts up to 100 image IDs per single call.

  <details style='padding: 0 0 1rem 1rem'>

  The `BatchDeleteImage` API raises `InvalidParameterException` if the `imageIds` list exceeds 100 entries.<br/>
  This limit is easy to hit when deleting multi-arch images (17 indices with ~9 children each produce ~153 digests in a
  single pass). Chunk deletion calls into slices of at most 100.

  ```python
  for i in range(0, len(digests_to_delete), 100):
      ecr.batch_delete_image(
          repositoryName=repo,
          imageIds=[{"imageDigest": d} for d in digests_to_delete[i:i+100]],
      )
  ```

  </details>

- Actively checking ECS clusters for currently used images requires to check both the desired state and the running
  state of tasks and services.

  <details style='padding: 0 0 1rem 1rem'>

  During a rolling deployment, old tasks continue running from the previous task definition revision. Querying only
  `service["taskDefinition"]` (the desired revision) leaves those tasks' images unprotected. Instead:

  1. Cover pending tasks whose containers have not pulled yet (desired state) with `list_services` → `describe_services`
     → `taskDefinition` ARNs → `describe_task_definition`.
  1. Cover tasks running from any revision, including old ones mid-rollout (running state) with
     `list_tasks(desiredStatus="RUNNING")` → `describe_tasks` (max 100 ARNs per call) → `container.image` +
     `container.imageDigest`.

  Use `desiredStatus="RUNNING"` instead of `lastStatus`. ECS never sets the desired status of a task to `PENDING`, so
  this captures tasks in the `PROVISIONING`, `ACTIVATING`, or `RUNNING` states.

  ```python
  running_arns: list[str] = []
  for p in ecs.get_paginator("list_tasks").paginate(cluster=cluster, desiredStatus="RUNNING"):
      running_arns.extend(p["taskArns"])
  for i in range(0, len(running_arns), 100):
      for task in ecs.describe_tasks(cluster=cluster, tasks=running_arns[i:i+100])["tasks"]:
          for container in task.get("containers", []):
              # see double-digest gotcha below before combining image + imageDigest
              img = container.get("image", "")
              img_digest = container.get("imageDigest", "")
              uri = f"{img}@{img_digest}" if img and img_digest and "@" not in img else img
              if uri:
                  protect(uri)
  ```

  </details>

- Container images in definitions may already use a digest. Be sure to account for that.

## Troubleshooting

### Docker pull errors with `no basic auth credentials`

Refer <https://github.com/awslabs/amazon-ecr-credential-helper/issues/207>.

Context: trying to pull an image on an EC2 instance that is using the amazon-ecr-credential-helper to login.

1. Check the user's `~/.ecr/log/ecr-login.log` file to get detailed information.
1. Check the user's `~/.docker/config.json` file has a correct PAT.
1. Check the instance's role has permissions to pull images.

## Further readings

- [Amazon Web Services]
- AWS' [CLI]
- [Use ECR as cache for BuildKit][announcing remote cache support in amazon ecr for buildkit clients]

### Sources

- [Using pull through cache rules]
- [Creating a lifecycle policy preview]
- [CLI subcommand reference]
- [Lifecycle policies]
- [Lifecycle policy parameters]
- [Repository creation templates]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Cleaning up old images]: #cleaning-up-old-images

<!-- Knowledge base -->
[amazon web services]: README.md
[cli]: cli.md

<!-- Files -->
<!-- Upstream -->
[announcing remote cache support in amazon ecr for buildkit clients]: https://aws.amazon.com/blogs/containers/announcing-remote-cache-support-in-amazon-ecr-for-buildkit-clients/
[cli subcommand reference]: https://docs.aws.amazon.com/cli/latest/reference/ecr/
[creating a lifecycle policy preview]: https://docs.aws.amazon.com/AmazonECR/latest/userguide/lpp_creation.html
[lifecycle policies]: https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html
[lifecycle policy parameters]: https://docs.aws.amazon.com/AmazonECR/latest/userguide/lifecycle_policy_parameters.html
[repository creation templates]: https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-creation-templates.html
[StartLifecyclePolicyPreview]: https://docs.aws.amazon.com/AmazonECR/latest/APIReference/API_StartLifecyclePolicyPreview.html
[Troubleshooting pull through cache issues in Amazon ECR]: https://docs.aws.amazon.com/AmazonECR/latest/userguide/error-pullthroughcache.html
[using pull through cache rules]: https://docs.aws.amazon.com/AmazonECR/latest/userguide/pull-through-cache.html
