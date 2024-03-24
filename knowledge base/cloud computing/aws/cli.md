# AWS CLI

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Profiles](#profiles)
1. [Configuration](#configuration)
1. [Session Manager integration](#session-manager-integration)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Do *not* use '--max-items' with '--query': the items limit is applied before the query filter, and could lead to no
results.

<details>
  <summary>Installation and configuration</summary>

```sh
# Install the CLI.
brew install 'awscli'

# Configure profiles.
aws configure
aws configure --profile 'work'

# Use specific profiles for the rest of the shell session.
export AWS_PROFILE='work'

# Enable auto-prompt mode (like `aws-shell` does).
aws configure set 'cli_auto_prompt' 'on-partial'
export AWS_CLI_AUTO_PROMPT='on'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# List applications in CodeDeploy.
aws deploy list-applications

# List deployment groups defined for applications.
aws deploy list-deployment-groups --application-name 'batman'

# Show details of deployment groups.
aws deploy get-deployment-group --application-name 'batman' \
  --deployment-group-name 'production'


# Show RDS instances.
aws rds describe-db-instances
aws rds describe-db-instances --output 'json' --query "DBInstances[?(DBInstanceIdentifier=='master-prod')]"


# List all SageMaker EndpointConfigurations' names.
aws sagemaker list-endpoint-configs --output 'yaml-stream' | yq -r '.[].EndpointConfigs[].EndpointConfigName' -
aws sagemaker list-endpoint-configs --output 'yaml-stream' --query 'EndpointConfigs[].EndpointConfigName' | yq -r '.[].[]' -
aws sagemaker list-endpoint-configs --output 'json' --query 'EndpointConfigs[].EndpointConfigName' | jq -r '.[]' -

# Describe all SageMaker EndpointConfigurations.
aws sagemaker list-endpoint-configs … \
| xargs -n '1' aws sagemaker describe-endpoint-config --endpoint-config-name


# List secrets stored in Secret Manager.
aws secretsmanager list-secrets

# Get information about secrets stored in Secret Manager.
aws secretsmanager describe-secret --secret-id 'ecr-pullthroughcache/docker-hub'

# Get secrets from Secret Manager.
aws secretsmanager get-secret-value --secret-id 'ecr-pullthroughcache/github'


# List SNS queues (a.k.a. 'topics').
aws sns list-topics


# Get information about the current user.
aws sts get-caller-identity

# List IAM users.
aws iam list-users
aws iam list-users --max-items '1'
aws iam list-users --query "Users[?(UserName=='mario')]"
aws iam list-users --query "Users[?(UserId=='AIDA…')].UserName"
```

Subcommands not listed here are in their own service-specific article:

[`ebs`][ebs tldr] |
[`ec2`][ec2 tldr] |
[`ecr`][ecr tldr] |
[`eks`][eks tldr] |
[`s3`][s3 tldr] |
[`ssm`][ssm tldr]

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Get roles' ARN from their name.
aws iam list-roles --query "Roles[?RoleName == 'EKSRole'].[RoleName, Arn]"

# Assume roles given their name.
aws iam list-roles --query "Roles[?RoleName == 'EKSRole'].Arn" --output 'text' \
| xargs -I {} \
  aws sts assume-role \
    --role-arn "{}" \
    --role-session-name "AWSCLI-Session"
```

</details>

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

## Configuration

| File                 | Description   |
| -------------------- | ------------- |
| `~/.aws/config`      | Configuration |
| `~/.aws/credentials` | Credentials   |

See [CLI config files] for examples.

## Session Manager integration

> The instance's IAM role must have at least the required permissions to allow to login.<br/>
> The bare minimum is for it to have the *SSM Minimum* role attached:
>
> ```sh
> $ aws iam list-attached-role-policies --role-name 'whatevah'
> AttachedPolicies:
>   - PolicyName: SSMMinimum
>     PolicyArn: arn:aws:iam::111122223333:policy/SSMMinimum
> ```

Install the Session Manager plugin:

```sh
# Install the signed package.
curl -O "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac_arm64/session-manager-plugin.pkg"
sudo installer -pkg 'session-manager-plugin.pkg' -target '/'

# Make the binary available to users.
# Pick one.
sudo ln -s '/usr/local/sessionmanagerplugin/bin/session-manager-plugin' '/usr/local/bin/session-manager-plugin'
ln -s '/usr/local/sessionmanagerplugin/bin/session-manager-plugin' "${HOME}/bin/session-manager-plugin"

# Verify it installed correctly.
session-manager-plugin
```

Then use it to get a session on the instance:

```sh
# Start sessions via Session Manager.
aws ssm start-session --target 'i-0123456789abcdef0'
```

## Further readings

- [AWS]
- CLI [quickstart]
- [Configure profiles] in the CLI
- [How do I assume an IAM role using the AWS CLI?]

### Sources

- [Improved CLI auto-prompt mode]
- [Install the Session Manager plugin for the AWS CLI]

<!--
  References
  -->

<!-- Knowledge base -->
[aws]: README.md
[ebs tldr]: ebs.md#tldr
[ec2 tldr]: ec2.md#tldr
[ecr tldr]: ecr.md#tldr
[eks tldr]: eks.md#tldr
[s3 tldr]: s3.md#tldr
[ssm tldr]: ssm.md#tldr

<!-- Files -->
[cli config files]: ../../../examples/dotfiles/.aws

<!-- Upstream -->
[configure profiles]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html
[how do i assume an iam role using the aws cli?]: https://repost.aws/knowledge-center/iam-assume-role-cli
[improved cli auto-prompt mode]: https://github.com/aws/aws-cli/issues/5664
[install the session manager plugin for the aws cli]: https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-macos-overview.html#install-plugin-macos-signed
[quickstart]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html
