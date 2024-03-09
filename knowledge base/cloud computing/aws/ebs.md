# Elastic Block Store

Persistent [block storage][what is block storage?] for [EC2 Instances][ec2].

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Real world use cases</summary>

```sh
# Clean up unused volumes.
aws ec2 describe-volumes --output 'text' \
  --filters 'Name=status,Values=available' --query 'Volumes[].VolumeId' \
| xargs -pn '1' aws ec2 delete-volume --volume-id
```

</details>

## Further readings

- [What is block storage?]

### Sources

- [Documentation]
- [Delete Unused AWS EBS Volumes]
- [`describe-volumes`][describe-volumes]
- [`delete-volume`][delete-volume]

<!--
  References
  -->

<!-- Knowledge base -->
[ec2]: ec2.md

<!-- Upstream -->
[delete-volume]: https://docs.aws.amazon.com/cli/latest/reference/ec2/delete-volume.html
[describe-volumes]: https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-volumes.html
[documentation]: https://docs.aws.amazon.com/ebs/
[what is block storage?]: https://aws.amazon.com/what-is/block-storage/

<!-- Others -->
[delete unused aws ebs volumes]: https://www.nops.io/unused-aws-ebs-volumes/
