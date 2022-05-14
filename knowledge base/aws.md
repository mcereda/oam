# AWS CLI

## TL;DR

```sh
# Install the CLI.
brew install awscli

# Configure a profile.
aws configure
aws configure --profile work

# Use a specific profile for the rest of this shell session.
export AWS_PROFILE="work"
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

## Sources

- CLI [quickstart]
- [Configure profiles] in the CLI

[quickstart]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html
[configure profiles]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html
