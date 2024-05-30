# Elastic Compute Cloud

1. [TL;DR](#tldr)
1. [Disks](#disks)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Use an instance profile to pass an IAM role to an EC2 instance.

<details>
  <summary>Real world use cases</summary>

```sh
# Get the IDs of running nginx instances in 'dev'.
aws ec2 describe-instances --output 'text' \
  --query 'Reservations[].Instances[].InstanceId[]'
  --filters \
    'Name=instance-state-name,Values=running' \
    'Name=tag:env,Values=dev' \
    'Name=tag:app,Values=nginx' \

# Start SSM sessions to specific machines.
aws ec2 describe-instances --output text \
  --query 'Reservations[].Instances[].InstanceId' \
  --filters \
    'Name=app,Values=mysql' \
    'Name=instance-state-name,Values=running' \
| xargs -ot aws ssm start-session --target

# Show images details.
aws ec2 describe-images --image-ids 'ami-8b8c57f8'
aws ec2 describe-images --filters \
  'Name=name,Values=["al2023-ami-minimal-*"]' \
  'Name=owner-alias,Values=["amazon"]' \
  'Name=architecture,Values=["arm64","x86_64"]' \
  'Name=block-device-mapping.volume-type,Values=["gp3"]'

# Describe security groups.
aws ec2 describe-security-groups --group-names 'pulumi-workshop'

# Delete security groups.
aws ec2 delete-security-group --group-name 'pulumi-workshop'
aws ec2 delete-security-group --group-id 'sg-0773aa724d0c2dd51'

# Query the onboard IMDSv1 metadata server.
curl 'http://instance-data/latest/meta-data/instance-id'
curl 'http://169.254.169.254/latest/meta-data/instance-type'
curl 'http://[fd00:ec2::254]/latest/meta-data/local-ipv4'
```

</details>

## Disks

See [EBS].

## Further readings

- [Amazon Web Services]
- [AWS EC2 Instance pricing comparison]
- [EC2Instances.info on vantage.sh]
- AWS' [CLI]
- [SSM]
- [Connect to your instances without requiring a public IPv4 address using EC2 Instance Connect Endpoint]

### Sources

- [Using instance profiles]
- [DescribeImages] API
- [`describe-images`][describe-images] CLI subcommand
- [Best practices for handling EC2 Spot Instance interruptions]
- [IAM roles for Amazon EC2]
- [Retrieve instance metadata]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[amazon web services]: README.md
[cli]: cli.md
[ebs]: ebs.md
[ssm]: ssm.md

<!-- Upstream -->
[best practices for handling ec2 spot instance interruptions]: https://aws.amazon.com/blogs/compute/best-practices-for-handling-ec2-spot-instance-interruptions/
[connect to your instances without requiring a public ipv4 address using ec2 instance connect endpoint]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-with-ec2-instance-connect-endpoint.html
[describe-images]: https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
[describeimages]: https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeImages.html
[iam roles for amazon ec2]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html
[retrieve instance metadata]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html
[using instance profiles]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html

<!-- Others -->
[aws ec2 instance pricing comparison]: https://ec2instances.github.io/
[ec2instances.info on vantage.sh]: https://instances.vantage.sh/
