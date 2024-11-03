#!/usr/bin/env fish

# List configured profiles
aws configure list-profiles

# Configure new profiles
aws configure --profile 'engineer'


# Assume roles
aws sts assume-role --role-arn 'arn:aws:iam::012345678901:role/ServiceRole' --role-session-name 'me-as-serviceRole'
aws --profile 'eng' sts assume-role --role-arn 'arn:aws:iam::012345678901:role/ServiceRole' --role-session-name 'eng-as-serviceRole'


# Check the credentials are fine
aws sts get-caller-identity
AWS_PROFILE='engineer' aws sts get-caller-identity


# Run as Docker container
docker run --rm -ti -v "$HOME/.aws:/root/.aws:ro" 'amazon/aws-cli:2.17.16' autoscaling describe-auto-scaling-groups