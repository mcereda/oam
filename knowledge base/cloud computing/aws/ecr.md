# Elastic Container Registry

1. [TL;DR](#tldr)
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
```

```sh
aws ecr describe-repositories --repository-names 'docker-tools/image-builder' \
|| aws ecr create-repository --repository-name 'docker-tools/image-builder'
```

## Pull through cache feature

> **Note:** when requesting an image for the first time using the pull through cache, the ECR creates a new repository
> for that image.<br>
> This might™ introduce a small latency and be cause of pull failures. Pulling that (not-yet)cached image from an
> interactive shell session worked flawlessly.

The user or role pulling the image must be granted the `ecr:BatchImportUpstreamImage` permission for the feature to
work as expected.

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
[using pull through cache rules]: https://docs.aws.amazon.com/AmazonECR/latest/userguide/pull-through-cache.html
[Troubleshooting pull through cache issues in Amazon ECR]: https://docs.aws.amazon.com/AmazonECR/latest/userguide/error-pullthroughcache.html
