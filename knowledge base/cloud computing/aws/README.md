# Amazon Web Services

1. [Networking](#networking)
1. [Services](#services)
   1. [CloudWatch](#cloudwatch)
1. [Config](#config)
1. [Resource constraints](#resource-constraints)
1. [Access control](#access-control)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Networking

VPCs define isolated virtual networking environments.<br/>
AWS accounts include one default VPC for each AWS Region. These allow for immediate launch and connection to EC2
instances.

Subnets are ranges of IP addresses in VPCs.<br/>
Each subnet resides in a single Availability Zone.<br/>
_Public_ subnets have a direct route to an Internet gateway. Resources in public subnets **can** access the public
Internet.<br/>
_Private_ subnets do **not** have a direct route to an Internet gateway. Resources in private subnets **require** a NAT
device to access the public internet.

Gateways connect VPCs to other networks.<br/>
[_Internet gateways_][connect to the internet using an internet gateway] connect VPCs to the Internet.<br/>
[_NAT gateways_][nat gateways] allow resources in private subnets to connect to the Internet, other VPCs, or on-premises
networks. They can communicate with services outside the VPC, but cannot receive unsolicited connection requests.<br/>
[_VPC endpoints_][access aws services through aws privatelink] connect VPCs to AWS services privately, without the need of Internet gateways or NAT devices.

## Services

| Service      | Description                                   |
| ------------ | --------------------------------------------- |
| [CloudWatch] | Observability (logging, monitoring, alerting) |
| [Config]     | FIXME                                         |
| [EC2]        | Virtual machines                              |
| [ECR]        | Container registry                            |
| [EKS]        | Kubernetes clusters                           |
| [S3]         | Storage                                       |
| [Sagemaker]  | Machine learning                              |

### CloudWatch

Observability service. with functions for logging, monitoring and alerting.

_Metrics_ are whatever needs to be monitored (e.g. CPU usage). _Data points_ are the values of a metric over time.
_Namespaces_ are containers for metrics.

Metrics only exist in the region in which they are created.

[Many AWS services][services that publish cloudwatch metrics] offer basic monitoring by publishing a default set of
metrics to CloudWatch with no charge.<br/>
This feature is automatically enabled by default when one starts using one of these services.

## Config

Compliance service for assessing and auditing AWS resources.

Records and monitors resource configurations.

Uses rules to evaluate whether the resources comply. Marks them with the evaluation result (_compliant_,
_non-compliant_).

Custom rules can be used to evaluate for uncommon requirements.<br/>
Custom rules leverage lambda functions.

Allows for automatic remediation for non-compliant resources by leveraging Systems Manager Automation documents.

_Conformance packs_ are set of rules bundled together as a deployable single entity.<br/>
Defined as YAML templates.<br/>
Immutable: users cannot make changes without updating the whole rule package.<br/>
Sample templates for compliance standards and benchmarks are available.

## Resource constraints

| Data type | Component | Summary                       | Description                                                                                                                                                                                                                                                | Type   | Length   | Pattern                           | Required |
| --------- | --------- | ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | -------- | --------------------------------- | -------- |
| Tag       | Key       | Required name of the tag      | The string value can be Unicode characters and cannot be prefixed with "aws:".<br/>The string can contain only the set of Unicode letters, digits, white-space, `_`,' `.`, `/`, `=`, `+`, `-`, `:`, `@` (Java regex: `^([\\p{L}\\p{Z}\\p{N}_.:/=+\\-]*)$`) | String | 1 to 128 | `^([\p{L}\p{Z}\p{N}_.:/=+\-@]*)$` | Yes      |
| Tag       | Value     | The optional value of the tag | The string value can be Unicode characters. The string can contain only the set of Unicode letters, digits, white-space, `_`, `.`, `/`, `=`, `+`, `-`, `:`, `@` (Java regex: `^([\\p{L}\\p{Z}\\p{N}_.:/=+\\-]*)$"`, `[\p{L}\p{Z}\p{N}_.:\/=+\-@]*` on AWS) | String | 0 to 256 | `^([\p{L}\p{Z}\p{N}_.:/=+\-@]*)$` | Yes      |

## Access control

| Entity | Description                                                                                                                     | Notes                                                  |
| ------ | ------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| User   | Represents a human or a workload.<br/>Defined by its name and credentials.                                                      | No permissions by default, need to be assigned to it   |
| Role   | Defines a set of permissions for making requests to AWS services.<br/>Defines what actions can be performed on which resources. | Can be assumed by AWS services, applications and users |

To be able to assume roles:

- Users, roles or services **must** have the permissions to assume the role they want to assume.
- The role's trust relationship **should** allow the users, roles or services to assume it.

From [Using service-linked roles]:

> A _service role_ is an IAM role that a service assumes to perform actions on your behalf.<br/>
> An IAM administrator can create, modify, and delete a service role from within IAM.
>
> A _service-linked role_ is a type of service role that is linked to an AWS service.<br/>
> The service can assume the role to perform an action on your behalf.<br/>
> Service-linked roles appear in your AWS account and are owned by the service. An IAM administrator can view, but not
> edit the permissions for service-linked roles.

## Further readings

- [EC2]
- [Services that publish CloudWatch metrics]
- [Using service-linked roles]
- [Best Practices for Tagging AWS Resources]

### Sources

- [Constraints for tags][constraints  tag]
- [What is CloudWatch]
- [What is Amazon VPC?]
- [Subnets for your VPC]
- [Introduction to AWS IAM AssumeRole]
- [AWS JSON policy elements: Principal]

<!--
  References
  -->

<!-- In-article sections -->
[cloudwatch]: #cloudwatch
[config]: #config

<!-- Knowledge base -->
[ec2]: ec2.md
[ecr]: ecr.md
[eks]: eks.md
[s3]: s3.md
[sagemaker]: sagemaker.md

<!-- Upstream -->
[access aws services through aws privatelink]: https://docs.aws.amazon.com/vpc/latest/privatelink/privatelink-access-aws-services.html
[aws json policy elements: principal]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html
[best practices for tagging aws resources]: https://docs.aws.amazon.com/whitepapers/latest/tagging-best-practices/tagging-best-practices.html
[connect to the internet using an internet gateway]: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html
[constraints  tag]: https://docs.aws.amazon.com/directoryservice/latest/devguide/API_Tag.html
[nat gateways]: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html
[services that publish cloudwatch metrics]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html
[subnets for your vpc]: https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html
[using service-linked roles]: https://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html
[what is amazon vpc?]: https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html
[what is cloudwatch]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html

<!-- Others -->
[introduction to aws iam assumerole]: https://aws.plainenglish.io/introduction-to-aws-iam-assumerole-fbef3ce8e90b
