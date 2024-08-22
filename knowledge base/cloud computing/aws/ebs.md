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

# Check state of snapshots.
aws ec2 describe-snapshots --snapshot-ids 'snap-0123456789abcdef0' \
  --query 'Snapshots[].{"State": State,"Progress": Progress}' --output 'yaml'

# Wait for snapshots to finish.
aws ec2 wait snapshot-completed --snapshot-ids 'snap-0123456789abcdef0'
```

</details>

Volumes can have their size **increased**, but **not** reduced.<br/>
After increase, the filesystem **must** be [extended][Extend the file system after resizing an EBS volume] to take
advantage of the change in size.<br/>
Apparently, Linux machines are able to do that automatically with a reboot.

## Snapshots

The first snapshot is **complete**, with all the volume's blocks being copied. All successive snapshots of the same
volume are **incremental**, with only the changes being copied.<br/>
Incremental snapshots are stored in EBS' standard tier.

Snapshots can be unbearably slow depending on the amount of data needing to be copied.<br/>
For comparison, the first snapshot of a 200 GiB volume took about 2h to complete.

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
- [Extend the file system after resizing an EBS volume]

### Sources

- [Documentation]
- [Delete Unused AWS EBS Volumes]
- [`describe-volumes`][describe-volumes]
- [`delete-volume`][delete-volume]
- [How do I increase or decrease the size of my EBS volume?]

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
[extend the file system after resizing an ebs volume]: https://docs.aws.amazon.com/ebs/latest/userguide/recognize-expanded-volume-linux.html
[how do i increase or decrease the size of my ebs volume?]: https://repost.aws/knowledge-center/ebs-increase-decrease-volume-size
[what is block storage?]: https://aws.amazon.com/what-is/block-storage/

<!-- Others -->
[delete unused aws ebs volumes]: https://www.nops.io/unused-aws-ebs-volumes/
