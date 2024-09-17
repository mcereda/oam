# AWS CLI

1. [TL;DR](#tldr)
1. [Profiles](#profiles)
1. [Configuration](#configuration)
1. [Session Manager integration](#session-manager-integration)
1. [Troubleshooting](#troubleshooting)
   1. [Installation with `pip` on Mac OS X errors out with message about the version of `six`](#installation-with-pip-on-mac-os-x-errors-out-with-message-about-the-version-of-six)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Do *not* use `--max-items` together with `--query`: the items limit is applied before the query filter, and could lead
to show no results.

<details>
  <summary>Setup</summary>

```sh
# Install the CLI.
brew install 'awscli'
docker pull 'amazon/aws-cli'
pip install 'awscli'

# Configure profiles.
aws configure
aws configure --profile 'work'

# Setup credentials in environment variables.
export \
  AWS_ACCESS_KEY_ID='AKIA2…A0TC' \
  AWS_SECRET_ACCESS_KEY='Lgb4…kko4'

# Use specific profiles for the rest of the shell session.
export AWS_PROFILE='work'

# Enable auto-prompt mode (like `aws-shell` does).
aws configure set 'cli_auto_prompt' 'on-partial'
export AWS_CLI_AUTO_PROMPT='on'

# Check the current configuration.
aws configure list

# Clear cached credentials.
rm -r ~'/.aws/cli/cache'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Use the docker version.
docker run --rm -ti -v "$HOME/.aws:/root/.aws:ro" 'amazon/aws-cli:2.17.16' autoscaling describe-auto-scaling-groups

# List applications in CodeDeploy.
aws deploy list-applications

# List deployment groups defined for applications.
aws deploy list-deployment-groups --application-name 'batman'

# Show details of deployment groups.
aws deploy get-deployment-group --application-name 'batman' \
  --deployment-group-name 'production'


# Get information about the current user.
aws sts get-caller-identity

# List IAM users.
aws iam list-users
aws iam list-users --max-items '1'
aws iam list-users --query "Users[?(UserName=='mario')]"
aws iam list-users --query "Users[?(UserId=='AIDA…')].UserName"

# Create IAM users.
aws iam create-user --user-name 'luigi'

# Create access keys.
# Defaults to the current user if no user name is specified.
aws iam create-access-key
aws iam create-access-key --user-name 'luigi'

# List access keys.
# Defaults to the current user if no user name is specified.
aws iam list-access-keys
aws iam list-access-keys --user-name 'mario'

# List configured OIDC providers.
aws iam list-open-id-connect-providers

# Create policies.
aws iam create-policy \
  --policy-name 'ro-access-bucket' --policy-document 'file://bucket.ro-access.policy.json'

# Delete policies.
aws iam delete-policy --policy-arn 'arn:aws:iam::012345678901:policy/ro-access-bucket'

# Attach policies.
aws iam attach-user-policy --user-name 'me-user' \
  --policy-arn 'arn:aws:iam::012345678901:policy/ro-access-bucket'

# Detach policies.
aws iam detach-user-policy --user-name 'me-user' \
  --policy-arn 'arn:aws:iam::012345678901:policy/ro-access-bucket'

# Delete user policies.
aws iam delete-user-policy --user-name 'me-user' --policy-name 'user-ro-access-bucket'


# Create new symmetric keys.
aws kms create-key

# Encrypt text.
aws kms encrypt --key-id '01234567-89ab-cdef-0123-456789abcdef' --plaintext 'My Test String'
aws kms encrypt --key-id '01234567-89ab-cdef-0123-456789abcdef' --plaintext 'My Test String' \
  --query 'CiphertextBlob' --output 'text' \
| base64 --decode > 'ciphertext.dat'

# Decrypt files.
aws kms decrypt --ciphertext-blob 'fileb://ciphertext.dat'
aws kms decrypt --ciphertext-blob 'fileb://ciphertext.dat' --query 'Plaintext' --output 'text' \
| base64 --decode


# List hosted zones.
aws route53 list-hosted-zones


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
```

Subcommands not listed here are in their own service-specific article:

[`ebs`][ebs tldr] |
[`ec2`][ec2 tldr] |
[`ecr`][ecr tldr] |
[`eks`][eks tldr] |
[`rds`][rds tldr] |
[`s3`][s3 tldr] |
[`ssm`][ssm tldr]

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Check the credentials are fine.
aws sts get-caller-identity

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

## Troubleshooting

### Installation with `pip` on Mac OS X errors out with message about the version of `six`

Context: on Mac OS X, during installation using `pip`

Error message example: FIXME error regarding the version of six that came with `distutils` in El Capitan.

Root cause: FIXME

Solutions:

- Use a virtual environment.
- Use the `--ignore-installed` option:

  ```sh
  sudo python -m 'pip' install 'awscli' --ignore-installed 'six'
  ```

## Further readings

- [Amazon Web Services]
- CLI [quickstart]
- [Configure profiles] in the CLI
- [How do I assume an IAM role using the AWS CLI?]
- [Yubikey authentication for AWS CLI (and boto) made easy]

### Sources

- [Improved CLI auto-prompt mode]
- [Install the Session Manager plugin for the AWS CLI]
- [Use an IAM role in the AWS CLI]
- [Using AWS KMS via the CLI with a Symmetric Key]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[amazon web services]: README.md
[ebs tldr]: ebs.md#tldr
[ec2 tldr]: ec2.md#tldr
[ecr tldr]: ecr.md#tldr
[eks tldr]: eks.md#tldr
[rds tldr]: rds.md#tldr
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
[use an iam role in the aws cli]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html
[using aws kms via the cli with a symmetric key]: https://nsmith.net/aws-kms-cli
[yubikey authentication for aws cli (and boto) made easy]: https://github.com/tommie-lie/awscli-plugin-yubikeytotp
