# AWS CLI

## TL;DR

```shell
# Install the CLI.
brew install awscli

# Configure a profile.
aws configure
aws configure --profile work

# Use a specific profile for the rest of this shell session.
export AWS_PROFILE="work"
```

## Profiles

```shell
# Initialize the default profile.
# Not specifying a profile means to configure the default profile.
$ aws configure
AWS Access Key ID [None]: AKIAI44QH8DHBEXAMPLE
AWS Secret Access Key [None]: je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: text

# Initialize a specific profile.
$ aws configure --profile work
AWS Access Key ID [None]: AKIAI44QH8DBEXAMPLE2
AWS Secret Access Key [None]: je7MtGbClwBF/2Zp9Utk/h3yCo8nbEXAMPLEKEY2
Default region name [None]: us-west-1
Default output format [None]: json

# Use a specific profile for the rest of this session.
$ export AWS_PROFILE="work"
```

## Further readings

- CLI [quickstart]
- [Configure profiles] in the CLI

[quickstart]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html
[configure profiles]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html
