# Elastic Block Store

Persistent [block storage][what is block storage?] for [EC2 Instances][ec2].

1. [TL;DR](#tldr)
1. [Snapshots](#snapshots)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Real world use cases</summary>

```sh
# Clean up unused volumes.
aws ec2 describe-volumes --output 'text' --filters 'Name=status,Values=available' \
  --query "Volumes[?CreateTime<'2018-03-31'].VolumeId" \
| xargs -pn '1' aws ec2 delete-volume --volume-id
```

</details>

## Snapshots

When created, snapshots are **incremental**.<br/>
Incremental snapshots are stored in EBS' standard tier.

Snapshots can be [archived][archive amazon ebs snapshots] to save money should they **not** need frequent nor fast
retrieval.<br/>
When archived, incremental snapshots are converted to **full snapshots** and moved to EBS' archive tier.

> The minimum archive period is 90 days.<br/>
> If deleting or permanently restoring an archived snapshot before the minimum archive period, one is billed for all the
> remaining days in the archive tier, rounded to the nearest hour.

When access to archived snapshots is needed, they need to be restored to the standard tier before use. Restoring can
take **up to 72h**.

## Further readings

- [Amazon Web Services]
- [What is block storage?]
- AWS' [CLI]
- [Archive Amazon EBS snapshots]
- [Automate snapshot lifecycles]
- [Choose the best Amazon EBS volume type for your self-managed database deployment]

### Sources

- [Documentation]
- [Delete Unused AWS EBS Volumes]
- [`describe-volumes`][describe-volumes]
- [`delete-volume`][delete-volume]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[amazon web services]: README.md
[cli]: cli.md
[ec2]: ec2.md

<!-- Upstream -->
[archive amazon ebs snapshots]: https://docs.aws.amazon.com/ebs/latest/userguide/snapshot-archive.html
[automate snapshot lifecycles]: https://docs.aws.amazon.com/ebs/latest/userguide/snapshot-ami-policy.html
[choose the best amazon ebs volume type for your self-managed database deployment]: https://aws.amazon.com/blogs/storage/how-to-choose-the-best-amazon-ebs-volume-type-for-your-self-managed-database-deployment/
[delete-volume]: https://docs.aws.amazon.com/cli/latest/reference/ec2/delete-volume.html
[describe-volumes]: https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-volumes.html
[documentation]: https://docs.aws.amazon.com/ebs/
[what is block storage?]: https://aws.amazon.com/what-is/block-storage/

<!-- Others -->
[delete unused aws ebs volumes]: https://www.nops.io/unused-aws-ebs-volumes/
