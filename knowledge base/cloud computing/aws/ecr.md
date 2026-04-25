# Elastic Container Registry

1. [TL;DR](#tldr)
1. [Lifecycle policies](#lifecycle-policies)
1. [Pull through cache feature](#pull-through-cache-feature)
1. [Troubleshooting](#troubleshooting)
   1. [Docker pull errors with `no basic auth credentials`](#docker-pull-errors-with-no-basic-auth-credentials)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

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

## Pull through cache feature

> **Note:** when requesting an image for the first time using the pull through cache, the ECR creates a new repository
> for that image.<br>
> This might™ introduce a small latency and be cause of pull failures. Pulling that (not-yet)cached image from an
> interactive shell session worked flawlessly.

The user or role pulling the image must be granted the `ecr:BatchImportUpstreamImage` permission for the feature to
work as expected. This is needed on **every** pull **and** applies also when the tag is already cached locally in the
ECR.<br/>
The service intercepts the pull request to check the upstream. Without this permission, ECR returns _not found_ (and
not _access denied_) intentionally.

Refer [Troubleshooting pull through cache issues in Amazon ECR].

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
