# Elastic File System

Serverless file storage for sharing files without the need for provisioning or managing storage capacity and
performance.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Built to scale on demand growing and shrinking automatically as files are added and removed.<br/>
Accessible across EC2, ECS, EKS, Lambda, and Fargate.

Supports the **NFS v4.0** and **v4.1** protocols.<br/>
A _mount target_ is required for any file system for clients to be able to use NFS to mount them.

The file system's DNS name automatically resolves to the mount target's IP address in the Availability Zone of the
connecting EC2 instances.<br/>
It follows the `{{ file-system-id }}.efs.{{ aws-region }}.amazonaws.com` convention.

Available file system types:

- _Regional_: redundant across **multiple** geographically separated AZs **within the same Region**.
- _One Zone_: data stored within a **single AZ**, with all the limits it implies.

Available throughput modes:

- _Elastic_: scales automatically in real time to meet the needs of workloads' activity.<br/>
  Only available for file systems using the General Purpose performance mode.<br/>
  Default setting when not specified during creation.
- _Provisioned_: statically provides the specified level of throughput independently from the file system's size.
- _Bursting_: scales automatically with the amount of data in Standard storage.

Available performance modes:

- _General Purpose_: lowest per-operation latency.<br/>
  Recommended for all file systems. Ideal for latency-sensitive applications.<br/>
  Examples: web-serving environments, content-management systems, home directories, and general file serving.
- _Max I/O_: designed for highly parallelized workloads that **can** tolerate higher latencies than the General Purpose
  mode.<br/>
  **Not** supported by One Zone file systems or file systems using the Elastic throughput mode.

Lifecycle management settings allow to automatically move files into and out of the lower-cost Infrequent Access storage
class based on access patterns.<br/>
Leverages lifecycle policies.

When creating file systems via the Console, the file system's lifecycle policy is configured by default with the
following settings:

- Transition into IA set to 30 days since last access.
- TransitionToArchive set to 90 days since last access.
- Transition into Standard set to None.

When creating file systems via the CLI or APIs, it is **not** possible to set lifecycle policies at the same time.<br/>
One **must** wait until the file system is created, then use the `PutLifecycleConfiguration` API operation to update the
lifecycle policies.

Provides file-system-access semantics like strong data consistency and file locking.<br/>
Supports:

- Controlling access to file systems through POSIX permissions.
- Authentication and authorization.
- Encryption in transit and at rest.

Encryption at rest is enabled when creating a file system. In such case, all data and metadata is encrypted.<br/>
Encryption in transit is enabled when mounting a file system. Client access via NFS to EFS is controlled by both IAM
policies and network security policies (i.e. security groups).

Windows-based EC2 instances are **not** supported.

Automatic backups are enabled by default when creating file systems using the console.<br/>
When creating file systems via the CLI or the APIs, automatic backups are enabled by default only when setting them up
to be One Zone file systems.

<details>
  <summary>Usage</summary>

```sh
# Get filesystems' information.
aws efs describe-file-systems --query 'FileSystems[]' --creation-token 'fs-name'

# Get filesystems's ids.
aws efs describe-file-systems --query 'FileSystems[].FileSystemId' --output 'text' --creation-token 'fs-name'

# Print filesystems's DNS.
# No DNS nor region are returned from the get fs command, but ARN is and the DNS does follow a naming convention, so…
aws efs describe-file-systems --query 'FileSystems[].FileSystemId' --output 'text' --creation-token 'fs-name' \
| sed -E 's|arn:[a-z-]+:elasticfilesystem:([a-z0-9-]+):[0-9]+:file-system/(fs-[a-f0-9]+)|\2.efs.\1.amazonaws.com|'

# Get mount targets' information.
aws efs describe-mount-targets --query 'MountTargets[]' --file-system-id 'fs-0123456789abcdef0'

# Get mount targets' IP address.
aws efs describe-mount-targets --query 'MountTargets[].IpAddress' --file-system-id 'fs-0123456789abcdef0'
aws efs describe-mount-targets --query 'MountTargets[].IpAddress' --mount-target-id 'fsmt-0123456789abcdef0'

# Get mount targets' IP address from the filesystem's name.
aws efs describe-mount-targets --query 'MountTargets[].IpAddress' --output 'json' --file-system-id \
"$(aws efs describe-file-systems --query 'FileSystems[].FileSystemId' --output 'text' --creation-token 'fs-name')"

# Mount volumes.
mount -t 'nfs' -o 'nfsvers=4.0,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport' \
  'fs-0123456789abcdef0.efs.eu-west-1.amazonaws.com:/' "$HOME/efs"
mount -t 'nfs' -o 'nfsvers=4,tcp,rwsize=1048576,hard,timeo=600,retrans=2,noresvport' \
  '10.20.30.42:/export-name' "$HOME/efs/export"
```

</details>

<details>
  <summary>Example: mount an EFS volume and change a file in it</summary>

```sh
$ aws efs describe-file-systems --query 'FileSystems[].FileSystemId' --output 'text' --creation-token 'mimir'
fs-abcdef0123456789a
$ dig 'A' +short '@172.16.0.2' 'fs-abcdef0123456789a.efs.eu-west-1.amazonaws.com'
172.16.1.20
$ mkdir -p "$HOME/tmp/efs"
$ mount -t 'nfs' -o 'nfsvers=4.0,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport' \
    '172.16.1.20:/' "$HOME/tmp/efs"
$ mount -t 'nfs'
172.16.1.20:/ on /Users/someuser/tmp/efs (nfs, nodev, nosuid, mounted by someuser)
$ sudo cp -iv 'config.yaml' "$HOME/tmp/efs/"   # EFS permissions require one to use `sudo` here
config.yaml -> /Users/someuser/tmp/efs/config.yaml
$ ls -l "$HOME/tmp/efs/"
total 1
-rw-r--r--@ 1 root  wheel  254 Apr 17 17:58 config.yaml
$ cat "$HOME/tmp/efs/config.yaml"
$ vim "$HOME/tmp/efs/config.yaml"
$ umount "$HOME/tmp/efs"
```

</details>

## Further readings

- [Amazon Web Services]
- [How do I mount, unmount, automount, and on-premises mount my Amazon EFS file system?]

### Sources

- [What is Amazon Elastic File System?]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[amazon web services]: README.md

<!-- Files -->
<!-- Upstream -->
[how do i mount, unmount, automount, and on-premises mount my amazon efs file system?]: https://repost.aws/knowledge-center/efs-mount-automount-unmount-steps
[what is amazon elastic file system?]: https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html

<!-- Others -->
