# Title

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
  'Name=name,Values=["al2023-ami-*"]' \
  'Name=owner-alias,Values=["amazon"]' \
  'Name=architecture,Values=["arm64","x86_64"]' \
  'Name=block-device-mapping.volume-type,Values=["gp3"]'
```

</details>

## Disks

See [EBS].

## Further readings

- [AWS EC2 Instance pricing comparison]
- [EC2Instances.info on vantage.sh]
- [SSM]

### Sources

- [Using instance profiles]
- [DescribeImages] API
- [`describe-images`][describe-images] CLI subcommand

<!--
  References
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[ebs]: ebs.md
[ssm]: ssm.md

<!-- Files -->
<!-- Upstream -->
[describe-images]: https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
[describeimages]: https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeImages.html
[using instance profiles]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html

<!-- Others -->
[aws ec2 instance pricing comparison]: https://ec2instances.github.io/
[ec2instances.info on vantage.sh]: https://instances.vantage.sh/
