# AWS CLI

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Profiles](#profiles)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Install the CLI.
brew install 'awscli'


# Configure profiles.
aws configure
aws configure --profile 'work'

# Use specific profiles for the rest of the shell session.
export AWS_PROFILE='work'


# Enable auto-prompt mode (like aws-shell).
aws configure set 'cli_auto_prompt' 'on-partial'
export AWS_CLI_AUTO_PROMPT='on'


# List all SageMaker EndpointConfigurations' names.
aws sagemaker list-endpoint-configs --output 'yaml-stream' | yq -r '.[].EndpointConfigs[].EndpointConfigName' -
aws sagemaker list-endpoint-configs --output 'yaml-stream' --query 'EndpointConfigs[].EndpointConfigName' | yq -r '.[].[]' -
aws sagemaker list-endpoint-configs --output 'json' --query 'EndpointConfigs[].EndpointConfigName' | jq -r '.[]' -

# Describe all SageMaker EndpointConfigurations.
aws sagemaker list-endpoint-configs … | xargs -n '1' aws sagemaker describe-endpoint-config --endpoint-config-name


# List secrets stored in Secret Manager.
aws secretsmanager list-secrets

# Get information about secrets stored in Secret Manager.
aws secretsmanager describe-secret --secret-id 'ecr-pullthroughcache/docker-hub'

# Get secrets from Secret Manager.
aws secretsmanager get-secret-value --secret-id 'ecr-pullthroughcache/github'
```

Non listed subcommand:

- [`aws ecr`][ecr tldr]
- [`aws s3`][s3 tldr]

## Profiles

```sh
# Initialize the default profile.
# Not specifying a profile means to configure the default profile.
$ aws configure
AWS Access Key ID [None]: AKIA…
AWS Secret Access Key [None]: je7MtG…
Default region name [None]: us-east-1
Default output format [None]: text

# Initialize a specific profile.
$ aws configure --profile work
AWS Access Key ID [None]: AKIA…
AWS Secret Access Key [None]: LB88Mt…
Default region name [None]: us-west-1
Default output format [None]: json

# Use a specific profile for the rest of this session.
$ export AWS_PROFILE="work"
```

## Further readings

- [AWS]
- CLI [quickstart]
- [Configure profiles] in the CLI

### Sources

- [Improved CLI auto-prompt mode]

<!--
  References
  -->

<!-- Knowledge base -->
[aws]: README.md
[ecr tldr]: ecr.md#tldr
[s3 tldr]: s3.md#tldr

<!-- Upstream -->
[quickstart]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html
[configure profiles]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html
[improved cli auto-prompt mode]: https://github.com/aws/aws-cli/issues/5664
