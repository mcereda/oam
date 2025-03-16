# Elastic Block Store

Persistent [block storage][what is block storage?] for [EC2 Instances][ec2].

1. [TL;DR](#tldr)
1. [Volume types](#volume-types)
1. [Snapshots](#snapshots)
1. [Encryption](#encryption)
1. [Operations](#operations)
   1. [Increase disks' size](#increase-disks-size)
   1. [Migrate `gp2` volumes to `gp3`](#migrate-gp2-volumes-to-gp3)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details style="padding-bottom: 1em;">
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

Every EBS volume is local to, and available in, a single Availability Zone.

Multiple EBS volumes can be attached to a single instance as long as both the volumes and the instance are in the same
Availability Zone.

Depending on the volume and instance types, multiple instances can mount a single volume at the same time.

Volumes can have their size **increased**, but **not** reduced.<br/>
The volumes' filesystem is **not** automatically extended during the change in size, and **must** be
[extended manually][Extend the file system after resizing an EBS volume] to take advantage of the change in size.<br/>
Linux-based instances should™ be able to take care of that automatically after reboot.

Volume costs depend on its type, provisioned size, IOPS and throughput.<br/>
Volumes are billed per-second increments, with a 60-seconds minimum period.<br/>
Refer [Amazon EBS pricing]

## Volume types

Refer [Amazon EBS volume types].

|                     | `gp3`                                            | `gp2`          | `io2`             | `io1`             | `st1`            | `sc1`            |
| ------------------- | ------------------------------------------------ | -------------- | ----------------- | ----------------- | ---------------- | ---------------- |
| Class               | SSD                                              | SSD            | SSD               | SSD               | HDD              | HDD              |
| Annual failure rate | 0.1% - 0.2%                                      | 0.1% - 0.2%    | 0.001%            | 0.1% - 0.2%       | 0.1% - 0.2%      | 0.1% - 0.2%      |
| Size                | 1 GiB - 16 TiB                                   | 1 GiB - 16 TiB | 4 GiB - 64 TiB    | 4 GiB - 16 TiB    | 125 GiB - 16 TiB | 125 GiB - 16 TiB |
| Max IOPS            | 16,000                                           | 16,000         | 256,000           | 64,000            | 500              | 250              |
| Max throughput      | 1,000 MiB/s                                      | 250 MiB/s      | 4,000 MiB/s       | 1,000 MiB/s       | 500 MiB/s        | 250 MiB/s        |
| Multi-attach        | No                                               | No             | Yes               | Yes               | No               | No               |
| NVMe reservations   | No                                               | No             | Yes               | No                | No               | No               |
| Bootable            | Yes                                              | Yes            | Yes               | Yes               | No               | No               |
| Pricing             | Per-GB + Per-IOPS over 3,000 + Per-MB/s over 125 | Per-GB         | Per-GB + Per-IOPS | Per-GB + Per-IOPS | Per-GB           | Per-GB           |

Billing is per-second increments, with a 60-seconds minimum period.

Pricing examples:

<details style="padding: 0 0 1em 1em; ">
  <summary><code>gp3</code>, 200 GB, 3000 IOPS, 512 MiB/s, for 69h 54m 34s in a 30d month in Ireland</summary>

```plaintext
Regional price (storage): $0.088/GB/month
Regional price (IOPS): $0.0055/IOPS/month over 3000
Regional price (throughput): $0.044/MB/s/month over 125

Seconds in a 30d month: 60s * 60m * 24h * 30d = 2592000s
Seconds of actual usage: 34s + ( 60s * 54m ) + ( 60s * 60m * 69h ) = 34s + 3240s + 248400s = 251674s

Storage costs: 200GB * $0.088/GB * ( 251674s / 2592000s ) = 200 * $0.088 * 0.09709645062 = $1.71
IOPS costs: ( 3000 - 3000 )IOPS * $0.0055/IOPS * ( 251674s / 2592000s ) = 0 * $0.0055 * 0.09709645062 = $0.00
Throughput costs: ( 512 - 125 )MB/s * $0.044/MB/s * ( 251674s / 2592000s ) = 387 * $0.044 * 0.09709645062 = $1.66

Total: $1.71 + $0.00 + $1.66 = $3.37
```

</details>

## Snapshots

A volume's first snapshot is a **complete** snapshot of it, with _all the volume's blocks_ being copied over.<br/>
All successive snapshots of the same volume are **incremental**, with _only the changes_ being copied over.<br/>
Incremental snapshots are stored in EBS' standard tier.

Snapshots can be unbearably slow depending on the amount of data needing to be copied.<br/>
For comparison, the first snapshot of a standard 200 GiB `gp3` volume took about 2h to complete.

Snapshots can be [archived][archive amazon ebs snapshots] to save money should they **not** need frequent nor fast
retrieval.<br/>
When archived, incremental snapshots are converted to **full snapshots** and moved to EBS' archive tier.

> The **minimum** archival period is **90 days**.<br/>
> Archived snapshots deleted or permanently restored before the end of the minimum archival period are billed for the
> whole period.

When access to archived snapshots is needed, they need to be restored to the standard tier before use. Restoring can
take **up to 72h**.

Lifecycle policies' `targetTags` attribute targets resources of the specified type in an **OR** fashion, not **AND**,
meaning they will target all resources with **at least one** of the defined target tags.

## Encryption

Refer [How Amazon EBS encryption works].

One can encrypt both boot and data volumes.

At the time of writing, only **symmetric** keys are supported.

Volumes attached to supported instance types encrypt the following types of data:

- Data **at rest** inside the volume.
- Data moving between the volume and the attached instance.
- Snapshots created from the volume.
- Volumes created from said snapshots.

Volumes are encrypted with a AES-256 data key.<br/>
The key is:

1. Generated by KMS.
1. Encrypted by KMS with another KMS-managed key.
1. Stored with the volume's information.

EBS automatically creates a unique AWS-managed key in **each** Region where one creates EBS resources, using the
`aws/ebs` alias. EBS then uses this KMS key for encryption by default.<br/>
Alternatively, one can use a **symmetric** customer managed encryption key of one's own creation.

EC2 integrates with KMS to encrypt and decrypt EBS volumes in ways that differ depending on whether the original
snapshot for encrypted volumes is itself encrypted or unencrypted.

<details>
  <summary>The original snapshot is <b>encrypted</b></summary>

1. EC2 sends a `GenerateDataKeyWithoutPlaintext` request to KMS specifying the KMS key for volume encryption.
1. If the volume is encrypted using the same key as the snapshot, KMS encrypts that key using that same data key as
   the snapshot.<br/>
   If the volume is encrypted using a different KMS key, KMS generates a new data key and encrypts it using the
   specified key. The encrypted data key is then sent to EBS to be stored with the volume metadata.
1. When attaching the encrypted volume to an instance, EC2 sends a `CreateGrant` request to KMS to be allowed to
   decrypt the data key.
1. KMS decrypts the encrypted data key and sends the decrypted data key to EC2.
1. EC2 uses the plaintext data key in the Nitro hardware to encrypt disk I/O to the volume.<br/>
   The plaintext data key persists in memory as long as the volume is attached to the instance.

</details>

<details style="padding-bottom: 1em;">
  <summary>The original snapshot is <b>not</b> encrypted</summary>

1. EC2 sends a `CreateGrant` request to KMS to be allowed to encrypt the volume that is being created from the snapshot.
1. EC2 sends a `GenerateDataKeyWithoutPlaintext` request to KMS specifying the key chosen for volume encryption.
1. KMS generates a new data key, encrypts it using the specified key, and sends the encrypted data key to EBS to be
   stored with the volume metadata.
1. EC2 sends a `Decrypt` request to KMS to decrypt the encrypted data key, which it then uses to encrypt the volume's
   data.
1. When attaching the encrypted volume to an instance, EC2 sends:

   1. A `CreateGrant` request to KMS to be allowed to decrypt the data key.
   1. A `Decrypt` request to KMS specifying the encrypted data key.

1. KMS decrypts the encrypted data key and sends the decrypted data key back to EC2.
1. EC2 uses the plaintext data key in the Nitro hardware to encrypt disk I/O to the volume.<br/>
   The plaintext data key persists in memory as long as the volume is attached to the instance.

</details>

When KMS keys become unusable, the effect is **almost immediately** subject to **eventual** consistency.<br/>
The key state of the impacted KMS keys change to reflect their new condition, and all requests to use those keys in
cryptographic operations fail.

EC2 encrypts all I/O to and from attached volumes using the **data** key, not the KMS key itself.<br/>
There is **no** immediate effect on the EC2 instance or its attached EBS volumes when performing actions that make KMS
keys unusable.

EBS removes data keys from the hardware when encrypted EBS volumes are detached from instances.<br/>
Attaching EBS volumes which data keys are encrypted with unusable KMS keys to EC2 instances will fail, because EBS will
not be able to use the KMS keys to decrypt the data key used for the volume.<br/>
Make the KMS key usable again to be able to attach such EBS volumes.

## Operations

### Increase disks' size

Refer [Modify an Amazon EBS volume using Elastic Volumes operations] and
[How do I increase or decrease the size of my EBS volume?].

1. Increase the volume's size:

   ```sh
   aws ec2 modify-volume --volume-type 'gp3' --volume-id 'vol-0123456789abcdef0' --size '750'
   aws ec2 describe-volumes-modifications --volume-ids 'vol-0123456789abcdef0' --output 'VolumesModifications[]'
   ```

1. Extend the volume's partitions from inside the instance using it:

   ```sh
   lsblk
   sudo growpart '/dev/nvme0n1' '1'  # nitro
   sudo growpart '/dev/xvda' '1'     # xen
   ```

1. Extend the volume's file system from inside the instance using it:

   ```sh
   sudo xfs_growfs -d '/'           # xfs
   sudo resize2fs '/dev/nvme0n1p1'  # ext4 on nitro
   sudo resize2fs '/dev/xvda1'      # ext4 on xen
   ```

### Migrate `gp2` volumes to `gp3`

See also [Hands-on Guide: How to migrate from gp2 to gp3 volumes and lower AWS cost].

It is **strongly advised** to take a snapshot of volumes before changing their type.

```sh
aws ec2 describe-volumes --filters "Name=volume-type,Values=gp2" --query 'Volumes[].VolumeId' --output 'text' \
| xargs -pn '1' aws ec2 modify-volume --volume-type 'gp3' --volume-id
```

## Further readings

- [Amazon Web Services]
- [What is block storage?]
- AWS' [CLI]
- [Archive Amazon EBS snapshots]
- [Automate snapshot lifecycles]
- [Choose the best Amazon EBS volume type for your self-managed database deployment]
- [Extend the file system after resizing an EBS volume]
- [Pricing][amazon ebs pricing]
- [Hands-on Guide: How to migrate from gp2 to gp3 volumes and lower AWS cost]

### Sources

- [Documentation]
- [Delete Unused AWS EBS Volumes]
- [`describe-volumes`][describe-volumes]
- [`delete-volume`][delete-volume]
- [Modify an Amazon EBS volume using Elastic Volumes operations]
- [How do I increase or decrease the size of my EBS volume?]
- [How Amazon EBS encryption works]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[amazon web services]: README.md
[cli]: cli.md
[ec2]: ec2.md

<!-- Upstream -->
[amazon ebs pricing]: https://aws.amazon.com/ebs/pricing/
[amazon ebs volume types]: https://docs.aws.amazon.com/ebs/latest/userguide/ebs-volume-types.html
[archive amazon ebs snapshots]: https://docs.aws.amazon.com/ebs/latest/userguide/snapshot-archive.html
[automate snapshot lifecycles]: https://docs.aws.amazon.com/ebs/latest/userguide/snapshot-ami-policy.html
[choose the best amazon ebs volume type for your self-managed database deployment]: https://aws.amazon.com/blogs/storage/how-to-choose-the-best-amazon-ebs-volume-type-for-your-self-managed-database-deployment/
[delete-volume]: https://docs.aws.amazon.com/cli/latest/reference/ec2/delete-volume.html
[describe-volumes]: https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-volumes.html
[documentation]: https://docs.aws.amazon.com/ebs/
[extend the file system after resizing an ebs volume]: https://docs.aws.amazon.com/ebs/latest/userguide/recognize-expanded-volume-linux.html
[how amazon ebs encryption works]: https://docs.aws.amazon.com/ebs/latest/userguide/how-ebs-encryption-works.html
[how do i increase or decrease the size of my ebs volume?]: https://repost.aws/knowledge-center/ebs-increase-decrease-volume-size
[modify an amazon ebs volume using elastic volumes operations]: https://docs.aws.amazon.com/ebs/latest/userguide/ebs-modify-volume.html
[what is block storage?]: https://aws.amazon.com/what-is/block-storage/

<!-- Others -->
[delete unused aws ebs volumes]: https://www.nops.io/unused-aws-ebs-volumes/
[hands-on guide: how to migrate from gp2 to gp3 volumes and lower aws cost]: https://www.stream.security/post/hands-on-guide-how-to-migrate-from-gp2-to-gp3-volumes
