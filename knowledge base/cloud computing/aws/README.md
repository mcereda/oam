# Amazon Web Services

1. [Networking](#networking)
   1. [Elastic IP addresses](#elastic-ip-addresses)
1. [Services](#services)
   1. [Billing and Cost Management](#billing-and-cost-management)
   1. [CloudWatch](#cloudwatch)
   1. [Config](#config)
   1. [Detective](#detective)
   1. [GuardDuty](#guardduty)
   1. [EventBridge](#eventbridge)
   1. [ImageBuilder](#imagebuilder)
   1. [Inspector](#inspector)
   1. [KMS](#kms)
   1. [Security Hub](#security-hub)
1. [Resource constraints](#resource-constraints)
1. [Access control](#access-control)
   1. [IAM policies](#iam-policies)
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
[_VPC endpoints_][access aws services through aws privatelink] connect VPCs to AWS services privately, without the need
of Internet gateways or NAT devices.

### Elastic IP addresses

Refer [Elastic IP addresses].

**Static**, **public** IPv4 addresses allocated to one's AWS account until one releases it.<br/>
One can can rapidly remapping addresses to other instances in one's account and use them as targets in DNS records.

## Services

| Service                       | Description                                   |
| ----------------------------- | --------------------------------------------- |
| [Billing and Cost Management] | FIXME                                         |
| [CloudWatch]                  | Observability (logging, monitoring, alerting) |
| [Config]                      | Compliance                                    |
| [Detective]                   | FIXME                                         |
| [EC2]                         | Virtual machines                              |
| [ECR]                         | Container registry                            |
| [ECS]                         | Containers as a service                       |
| [EKS]                         | Kubernetes clusters                           |
| [EventBridge]                 | FIXME                                         |
| [GuardDuty]                   | Threat detection                              |
| [ImageBuilder]                | Build custom AMIs                             |
| [Inspector]                   | FIXME                                         |
| [KMS]                         | Key management                                |
| [OpenSearch]                  | ELK, logging                                  |
| [RDS]                         | Databases                                     |
| [S3]                          | Storage                                       |
| [Sagemaker]                   | Machine learning                              |
| [Security Hub]                | Aggregator for security findings              |

[Service icons][aws icons] are publicly available for diagrams and such.

### Billing and Cost Management

Costs can be grouped by Tags applied on resources.<br/>
Tags to use for this kind of grouping need to be activated in the _Cost allocation tags_ section.<br/>
New tags might take 24 or 48 hours to appear there.

### CloudWatch

Observability service. with functions for logging, monitoring and alerting.

_Metrics_ are whatever needs to be monitored (e.g. CPU usage). _Data points_ are the values of a metric over time.
_Namespaces_ are containers for metrics.

Metrics only exist in the region in which they are created.

[Many AWS services][services that publish cloudwatch metrics] offer basic monitoring by publishing a default set of
metrics to CloudWatch with no charge.<br/>
This feature is automatically enabled by default when one starts using one of these services.

### Config

Compliance service for assessing and auditing AWS resources.

Provides an inventory of resources.<br/>
Records and monitors resource configurations and their changes.<br/>
The data is stored in a bucket (default name `config-bucket-{aws-account-number}`)<br/>
Changes can be streamed to 1 SNS topic for notification purposes.<br/>
Uses _rules_ to evaluate whether the resources configurations comply.<br/>
Rule evaluation is done once every time a configuration changes, or periodically.<br/>
Resources are marked with the evaluation result (_compliant_, _non-compliant_).

Custom rules can be used to evaluate for uncommon requirements.<br/>
Custom rules leverage lambda functions.

Allows for automatic remediation for non-compliant resources by leveraging Systems Manager Automation documents.

_Conformance packs_ are set of rules bundled together as a deployable single entity.<br/>
Defined as YAML templates.<br/>
Immutable: users cannot make changes without updating the whole rule package.<br/>
Sample templates for compliance standards and benchmarks are available.

### Detective

Uses ML and graphs to try and identify the root cause of security issues.<br/>
Creates visualizations with details and context by leveraging events from VPC Flow Logs, CloudTrail and GuardDuty.

### GuardDuty

Threat detection service.

It continuously monitors accounts and workloads for malicious activity and delivers security findings for visibility and
remediation.<br/>
Done by pulling streams of data from CloudTrail, VPC Flow Logs or EKS.

Member accounts can administer GuardDuty by delegation if given the permissions to do so.

_Findings_ are **potential** security issues for malicious events.<br/>
Those are also sent to EventBridge for notification (leveraging SNS).<br/>
Each is assigned a severity value (0.1 to 8+).

_Trusted IP List_ is a whitelist of **public IPs** that will be ignored by the rules.<br/>
_Threat IP List_ is a blacklist of **public IPs and CIDRs** that will be used by the rules.<br/>

### EventBridge

TODO

### ImageBuilder

Also refer [Image baking in AWS using Packer and Image builder].

### Inspector

TODO

### KMS

_Key material_ is the cryptographic secret of Keys that is used in encryption operations.

Enabling automatic key rotation for a KMS key makes the service generate new cryptographic material for the key every
year by default.<br/>
Specify a custom rotation period to customize that time frame.

Perform on-demand rotation should you need to immediately initiate key material rotation.<br/>
This works regardless of whether the automatic key rotation is enabled or not. On-demand rotations do **not** change
existing automatic rotation schedules.

KMS saves **all** previous versions of the cryptographic material in perpetuity to allow decryption of any data
encrypted with keys.<br/>
Rotated key material is **not** deleted until the key itself is deleted.

Track the rotation of key material [CloudWatch], CloudTrail, and the KMS console.<br/>
Alternatively, use the `GetKeyRotationStatus` operation to verify whether automatic rotation is enabled for a key and
identify any in progress on-demand rotations. Use the `ListKeyRotations` operation to view the details of completed
rotations.

When using a rotated KMS key to encrypt data, KMS uses the **current** key material.<br/>
When using the same rotated KMS key to decrypt ciphertext, KMS uses the version of the key material that was used for
encryption.<br/>
One **cannot** select a particular version of key materials for decrypt operations. This automation allows to safely use
rotated KMS keys in applications and AWS services without code changes.

Automatic key rotation has no effect on the data that KMS keys protect: it does **not** rotate the data generated by
rotated keys, re-encrypts any data protected by the keys, nor it will mitigate the effect of compromised data keys.

KMS supports automatic and on-demand key rotation only for symmetric encryption keys with key material that KMS itself
creates.<br/>
Automatic rotation is optional for customer managed KMS keys. KMS rotates the key material for AWS managed keys on an
yearly basis. Rotation of AWS owned KMS keys is managed by the AWS service that owns the key.

Key rotation only changes the key material, not the key's properties.<br/>
The key is considered the same logical resource, regardless of whether or how many times its key material changes.

Creating a new key and using it in place of the original one has the same effect as rotating the key material in an
existing key.<br/>
This is considered a _manual_ key rotation and is a good choice to rotate keys that are not eligible for automatic key
rotation.

AWS charges a monthly fee for the first and second rotation of key material maintained for each key.<br/>
This price increase is capped at the second rotation. Any subsequent rotations will **not** be billed.

Each key counts as one when calculating key resource quotas, regardless of the number of rotated key material versions.

### Security Hub

Aggregator of findings for security auditing.

> Uses [Config] to check resources' configuration by leveraging compliancy rules.

Security standards are offered as ret of rules for [Config].

Data can be aggregated from different regions.<br/>
If the integration is enabled, findings from AWS services ([GuardDuty]) are used too within 5 minutes on average, while
ones from 3rd parties can take longer.

Data can be imported from or exported to 3rd parties if the integration is enabled.<br/>
Kinda acts as a middle layer for AWS accounts.

Findings are consumed in _AWS Security Finding Format_ (ASFF).<br/>
Those are automatically updated and deleted. Findings after 90 days are automatically deleted even if **not** resolved.

Can use custom insights.

Custom actions can be sent to EventBridge for automation.

Member accounts can administer Security Hub by delegation if given the permissions to do so.

## Resource constraints

| Data type    | Component | Summary                                    | Description                                                                                                                                                                                                                                                | Type   | Length   | Pattern                           | Required |
| ------------ | --------- | ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | -------- | --------------------------------- | -------- |
| Statement ID | Value     | Optional identifier for a policy statement | The element supports only ASCII uppercase letters (A-Z), lowercase letters (a-z), and numbers (0-9).                                                                                                                                                       | String | FIXME    | `[A-Za-z0-9]`                     | No       |
| Tag          | Key       | Required name of the tag                   | The string value can be Unicode characters and cannot be prefixed with "aws:".<br/>The string can contain only the set of Unicode letters, digits, white-space, `_`,' `.`, `/`, `=`, `+`, `-`, `:`, `@` (Java regex: `^([\\p{L}\\p{Z}\\p{N}_.:/=+\\-]*)$`) | String | 1 to 128 | `^([\p{L}\p{Z}\p{N}_.:/=+\-@]*)$` | Yes      |
| Tag          | Value     | The optional value of the tag              | The string value can be Unicode characters. The string can contain only the set of Unicode letters, digits, white-space, `_`, `.`, `/`, `=`, `+`, `-`, `:`, `@` (Java regex: `^([\\p{L}\\p{Z}\\p{N}_.:/=+\\-]*)$"`, `[\p{L}\p{Z}\p{N}_.:\/=+\-@]*` on AWS) | String | 0 to 256 | `^([\p{L}\p{Z}\p{N}_.:/=+\-@]*)$` | Yes      |

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

Check [aws.permissions.cloud] for a community-driven source of truth for AWS identity.

### IAM policies

IAM does not expose policies' `Sid` element in the IAM API, so it can't be used to retrieve statements.

Examples:

<details>
  <summary>Give a user temporary RO access to a bucket</summary>

1. Create the policy:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Sid": "AllowAttachedPrincipalsTemporaryROAccessToBucket",
       "Effect": "Allow",
       "Action": [
         "s3:GetObject",
         "s3:GetObjectAttributes",
         "s3:ListBucket",
         "s3:ListBucketVersions"
       ],
       "Resource": [
         "arn:aws:s3:::my-bucket",
         "arn:aws:s3:::my-bucket/*"
       ],
       "Condition": {
         "DateLessThan": {
           "aws:CurrentTime": "2024-03-01T00:00:00Z"
         }
       }
     }]
   }
   ```

   ```sh
   $ aws iam create-policy --output 'yaml' \
     --policy-name 'temp-ro-access-my-bucket' --policy-document 'file://policy.json'
   - Policy:
       Arn: arn:aws:iam::012345678901:policy/temp-ro-access-my-bucket
       AttachmentCount: 0
       CreateDate: '2024-02-25T09:34:12+00:00'
       DefaultVersionId: v1
       IsAttachable: true
       Path: /
       PermissionsBoundaryUsageCount: 0
       PolicyId: ANPA2HKHE74L11PTJGB3V
       PolicyName: temp-ro-access-my-bucket
       UpdateDate: '2024-02-25T09:34:12+00:00'
   ```

1. Attach the newly created policy to the user:

   ```sh
   aws iam attach-user-policy \
     --user-name 'my-user' --policy-arn 'arn:aws:iam::012345678901:policy/temp-ro-access-my-bucket'
   ```

</details>

## Further readings

- [EC2]
- [Services that publish CloudWatch metrics]
- [Using service-linked roles]
- [Best Practices for Tagging AWS Resources]
- [Automating DNS-challenge based LetsEncrypt certificates with AWS Route 53]
- AWS' [CLI]
- [Configuring EC2 Disk alert using Amazon CloudWatch]
- [aws.permissions.cloud]

### Sources

- [Constraints for tags][constraints  tag]
- [What is CloudWatch]
- [What is Amazon VPC?]
- [Subnets for your VPC]
- [Introduction to AWS IAM AssumeRole]
- [AWS JSON policy elements: Principal]
- [What is AWS Config?]
- [AWS Config tutorial by Stephane Maarek]
- [Date & time policy conditions at AWS - 1-minute IAM lesson]
- [IAM JSON policy elements: Sid]
- [Elastic IP addresses]
- [Using IAM policy conditions for fine-grained access control to manage resource record sets]
- [Not authorized to perform: sts:AssumeRole]
- [Test Your Roles' Access Policies Using the AWS Identity and Access Management Policy Simulator]
- [Troubleshooting IAM roles]
- [How can I monitor the account activity of specific IAM users, roles, and AWS access keys?]
- [Using IAM roles]
- [AssumeRole api reference]
- [You might be clueless as to why AWS assume role isn't working, despite being correctly set up]
- [Use an IAM role in the AWS CLI]
- [Creating a role to delegate permissions to an IAM user]
- [How to use the PassRole permission with IAM roles]
- [Exporting DB snapshot data to Amazon S3]
- [I'm trying to export a snapshot from Amazon RDS MySQL to Amazon S3, but I'm receiving an error. Why is this happening?]
- [Rotating AWS KMS keys]
- [Image baking in AWS using Packer and Image builder]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[billing and cost management]: #billing-and-cost-management
[cloudwatch]: #cloudwatch
[config]: #config
[detective]: #detective
[eventbridge]: #eventbridge
[guardduty]: #guardduty
[imagebuilder]: #imagebuilder
[inspector]: #inspector
[kms]: #kms
[security hub]: #security-hub

<!-- Knowledge base -->
[cli]: cli.md
[ec2]: ec2.md
[ecr]: ecr.md
[ecs]: ecs.md
[eks]: eks.md
[opensearch]: opensearch.md
[rds]: rds.md
[s3]: s3.md
[sagemaker]: sagemaker.md

<!-- Upstream -->
[access aws services through aws privatelink]: https://docs.aws.amazon.com/vpc/latest/privatelink/privatelink-access-aws-services.html
[assumerole api reference]: https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html
[aws icons]: https://aws-icons.com/
[aws json policy elements: principal]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html
[best practices for tagging aws resources]: https://docs.aws.amazon.com/whitepapers/latest/tagging-best-practices/tagging-best-practices.html
[connect to the internet using an internet gateway]: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html
[constraints  tag]: https://docs.aws.amazon.com/directoryservice/latest/devguide/API_Tag.html
[creating a role to delegate permissions to an iam user]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user.html
[elastic ip addresses]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html
[exporting db snapshot data to amazon s3]: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ExportSnapshot.html
[how can i monitor the account activity of specific iam users, roles, and aws access keys?]: https://repost.aws/knowledge-center/view-iam-history
[how to use the passrole permission with iam roles]: https://aws.amazon.com/blogs/security/how-to-use-the-passrole-permission-with-iam-roles/
[i'm trying to export a snapshot from amazon rds mysql to amazon s3, but i'm receiving an error. why is this happening?]: https://repost.aws/knowledge-center/rds-mysql-export-snapshot
[iam json policy elements: sid]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_sid.html
[nat gateways]: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html
[not authorized to perform: sts:assumerole]: https://repost.aws/questions/QUOY5XngCtRyOX4Desaygz8Q/not-authorized-to-perform-sts-assumerole
[rotating aws kms keys]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html
[services that publish cloudwatch metrics]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html
[subnets for your vpc]: https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html
[test your roles' access policies using the aws identity and access management policy simulator]: https://aws.amazon.com/blogs/security/test-your-roles-access-policies-using-the-aws-identity-and-access-management-policy-simulator/
[troubleshooting iam roles]: https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_roles.html
[use an iam role in the aws cli]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html
[using iam policy conditions for fine-grained access control to manage resource record sets]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/specifying-rrset-conditions.html
[using iam roles]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html
[using service-linked roles]: https://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html
[what is amazon vpc?]: https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html
[what is aws config?]: https://docs.aws.amazon.com/config/latest/developerguide/WhatIsConfig.html
[what is cloudwatch]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html

<!-- Others -->
[automating dns-challenge based letsencrypt certificates with aws route 53]: https://johnrix.medium.com/automating-dns-challenge-based-letsencrypt-certificates-with-aws-route-53-8ba799dd207b
[aws config tutorial by stephane maarek]: https://www.youtube.com/watch?v=qHdFoYSrUvk
[aws.permissions.cloud]: https://aws.permissions.cloud/
[configuring ec2 disk alert using amazon cloudwatch]: https://medium.com/@chandinims001/configuring-ec2-disk-alert-using-amazon-cloudwatch-793807e40d72
[date & time policy conditions at aws - 1-minute iam lesson]: https://www.youtube.com/watch?v=4wpKP1HLEXg
[image baking in aws using packer and image builder]: https://dev.to/santhoshnimmala/image-baking-in-aws-using-packer-and-image-builder-1ed3
[introduction to aws iam assumerole]: https://aws.plainenglish.io/introduction-to-aws-iam-assumerole-fbef3ce8e90b
[you might be clueless as to why aws assume role isn't working, despite being correctly set up]: https://medium.com/@kamal.maiti/you-might-be-clueless-as-to-why-aws-assume-role-isnt-working-despite-being-correctly-set-up-1b3138519c07
