# Elastic File System

Serverless file storage for sharing files without the need for provisioning or managing storage capacity and
performance.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Built to scale on demand growing and shrinking automatically as files are added and removed.<br/>
Accessible across most types of AWS compute instances, including EC2, ECS, EKS, Lambda, and Fargate.

Supports the NFS v4.0 and v4.1 protocols.

Available file system types:

- _Regional_: redundant across **multiple** geographically separated AZs **within the same Region**.
- _One Zone_: data stored within a **single AZ**, with all the limits it implies.

Default modes:

- _General Purpose Performance_: ideal for latency-sensitive applications.<br/>
  Examples: web-serving environments, content-management systems, home directories, and general file serving.
- _Elastic Throughput_: designed to scale throughput performance automatically to meet the needs of workloads' activity.

Provides file-system-access semantics like strong data consistency and file locking.<br/>
Supports controlling access to file systems through POSIX permissions.<br/>
Supports authentication, authorization, and encryption.

EFS supports encryption in transit and encryption at rest.<br/>
Encryption at rest is enabled when creating a file system. In such case, all data and metadata is encrypted.<br/>
Encryption in transit is enabled when mounting a file system. Client access via NFS to EFS is controlled by both IAM
policies and network security policies (i.e. security groups).

Windows-based EC2 instances are **not** supported.

## Further readings

- [Amazon Web Services]

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
[what is amazon elastic file system?]: https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html

<!-- Others -->
