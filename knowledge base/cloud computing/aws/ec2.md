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
```

</details>

## Disks

See [EBS].

## Further readings

- [AWS EC2 Instance pricing comparison]
- [EC2Instances.info on vantage.sh]

### Sources

- [Using instance profiles]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[ebs]: ebs.md
[ssm]: ssm.md

<!-- Files -->
<!-- Upstream -->
[using instance profiles]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html

<!-- Others -->
[aws ec2 instance pricing comparison]: https://ec2instances.github.io/
[ec2instances.info on vantage.sh]: https://instances.vantage.sh/
