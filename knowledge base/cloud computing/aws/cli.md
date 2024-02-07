# AWS CLI

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Profiles](#profiles)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Install the CLI.
brew install 'awscli'


# Configure profiles.
aws configure
aws configure --profile 'work'

# Use specific profiles for the rest of the shell session.
export AWS_PROFILE='work'


# List all SageMaker EndpointConfigurations' names.
aws sagemaker list-endpoint-configs --output 'yaml-stream' | yq -r '.[].EndpointConfigs[].EndpointConfigName' -
aws sagemaker list-endpoint-configs --output 'yaml-stream' --query 'EndpointConfigs[].EndpointConfigName' | yq -r '.[].[]' -
aws sagemaker list-endpoint-configs --output 'json' --query 'EndpointConfigs[].EndpointConfigName' | jq -r '.[]' -

# Describe all SageMaker EndpointConfigurations.
aws sagemaker list-endpoint-configs … | xargs -n '1' aws sagemaker describe-endpoint-config --endpoint-config-name
```

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

- CLI [quickstart]
- [Configure profiles] in the CLI

<!--
  References
  -->

<!-- Upstream -->
[quickstart]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html
[configure profiles]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html
