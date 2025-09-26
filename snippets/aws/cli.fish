#!/usr/bin/env fish

# List the current configuration
aws configure list


# List configured profiles
aws configure list-profiles

# Configure new profiles
aws configure --profile 'engineer'


# Assume roles
aws sts assume-role --role-arn 'arn:aws:iam::012345678901:role/ServiceRole' --role-session-name 'me-as-serviceRole'
aws --profile 'engineer' sts assume-role \
	--role-arn 'arn:aws:iam::012345678901:role/ServiceRole' \
	--role-session-name 'engineer-as-serviceRole' \
	--duration-seconds '10800'


# Check the credentials are fine
aws sts get-caller-identity
AWS_PROFILE='engineer' aws sts get-caller-identity

# Clear cached credentials
rm -r ~'/.aws/cli/cache'


# Get temporary credentials
aws sts get-session-token
aws sts get-session-token --serial-number 'arn:aws:iam::123456789012:mfa/some-device' --token-code 'code-from-token'

# Use temporary credentials
export \
	AWS_ACCESS_KEY_ID='access-key-from-get-session-output' \
	AWS_SECRET_ACCESS_KEY='secret-access-key-from-get-session-output' \
    AWS_SESSION_TOKEN='session-token-from-get-session-output'


# Run as Docker container
docker run --rm -ti 'amazon/aws-cli' --version
docker run --rm -ti -v "$HOME/.aws:/root/.aws:ro" 'amazon/aws-cli:2.17.16' autoscaling describe-auto-scaling-groups
