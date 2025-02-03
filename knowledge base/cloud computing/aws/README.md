# Amazon Web Services

1. [TL;DR](#tldr)
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
1. [Savings plans](#savings-plans)
1. [Resource tagging](#resource-tagging)
1. [API](#api)
   1. [Python](#python)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

_Regions_ are physical world locations where multiple Availability Zones exist.<br/>
They are physically isolated and independent from one another.<br/>
Regions come at **no** charge.

_Availability Zones_ are sets of one or more data centers, each with their own resources, housed in separate facilities.

Resources created in one Region do **not** exist in any other Region, unless explicitly using replication features
offered by AWS services.<br/>
Some services like IAM do **not** have Regional resources.

Recommended using regional STS endpoints instead of [the global one](https://sts.amazonaws.com) to reduce latency.<br/>
Session tokens from regional STS endpoints are valid in **all** AWS Regions. However, tokens from the global endpoint
are only valid in enabled Regions.

Session tokens valid in all Regions are larger. If storing session tokens, these might affect one's systems.

Regions introduced before 2019-03-20 are enabled by default. Newer regions are now disabled by default.<br/>
Regions enabled by default **cannot be enabled or disabled**.

Disabling Regions disables IAM access to resources in those Region. It will **not** delete resources in the disabled
region, and they **will** continue to be charged at the standard rate.

Disabling a Region can takes a few minutes to several hours to take effect. Services and Console will be visible until
the region is completely disabled.

Enabling Regions takes a few minutes to several hours. They **cannot** be used until the preparation process is
complete.

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
| [EC2]                         | Managed virtual machines                      |
| [ECR]                         | Container registry                            |
| [ECS]                         | Run containers as a service                   |
| [EFS]                         | Serverless file storage                       |
| [EKS]                         | Managed Kubernetes clusters                   |
| [EventBridge]                 | FIXME                                         |
| [GuardDuty]                   | Threat detection                              |
| [IAM]                         | Access control                                |
| [ImageBuilder]                | Build custom AMIs                             |
| [Inspector]                   | FIXME                                         |
| [KMS]                         | Key management                                |
| [OpenSearch]                  | ELK, logging                                  |
| [RDS]                         | Databases                                     |
| [Route53]                     | DNS                                           |
| [S3]                          | Storage                                       |
| [Sagemaker]                   | Machine learning                              |
| [Security Hub]                | Aggregator for security findings              |
| [SNS]                         | Pub/sub message delivery                      |
| [SQS]                         | Queues                                        |

[Service icons][aws icons] are publicly available for diagrams and such.
Public service IP address ranges are [available in JSON form][aws public ip address ranges now available in json form]
at <https://ip-ranges.amazonaws.com/ip-ranges.json>.

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

Refer [IAM].

## Savings plans

Refer [Savings Plans user guide].

Pricing models offering lower prices compared to On-Demand prices. They require specific usage commitments ($/hour) for
1-**year** or 3-**years** terms.

Dedicated Instances, Spot Instances and Reserved Instances are **not** discounted by Savings Plans.

| Savings Plan     | Included resources                                                                                                                                                                                                                                                                     | Up to |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| Compute          | EC2 instances regardless of family, size, AZ, region, OS or tenancy<br/>Lambda<br/>Fargate                                                                                                                                                                                             | 66%   |
| EC2 Instance     | **Individual** EC2 instance families in a specific region (e.g. M5 usage in N. Virginia) regardless of AZ, size, OS or tenancy                                                                                                                                                         | 72%   |
| Amazon SageMaker | **Eligible** SageMaker ML instances, including SageMaker Studio Notebook, SageMaker On-Demand Notebook, SageMaker Processing, SageMaker Data Wrangler, SageMaker Training, SageMaker Real-Time Inference, and SageMaker Batch Transform regardless of instance family, size, or region | 64%   |

Both Compute and EC2 Instance plan types apply to EC2 instances that are a part of Amazon EMR, Amazon EKS, and
Amazon ECS clusters. They do **not** apply to RDS instances.<br/>
Charges for the EKS service itself will not be covered by Savings Plans, but the underlying EC2 instances will be.

Savings Plans are available in the following payment options:

- _No Upfront_: no upfront payments, commitment charged purely on a monthly basis.
- _Partial Upfront_: lower prices, at least half of one's commitment upfront, remainder charged on a monthly basis.
- _All Upfront_: lowest prices, entire commitment charged in one payment at the start.

Savings Plans can be purchased in any account within an AWS Organization/Consolidated Billing family.<br/>
By default, the benefits of the Plans are applicable to usage across **all** accounts. One can **choose** to restrict
the benefit of the Plans to only the account that purchased them.

One account **can** have multiple Savings Plans active at the same time.

Plans **cannot** be cancelled during their term.<br/>
Plans **can** be _returned_ only if:

- They consist in an hourly commitment of $100 or less.
- They have been purchased in the past 7 days **and** in the same calendar month.

Once returned, one will receive a 100% refund for any upfront charges for the Savings Plan.<br/>
Refunds will be reflected in one's bill within 24 hours of return.

Any usage covered by the plan **will be charged at On-Demand rates**, or get covered by a different Savings Plans _if
applicable_.

Plans do **not** provide capacity reservations.<br/>
One **can** however reserve capacity with On Demand Capacity Reservations and pay lower prices on them with Savings
Plans.

EC2 Instance Savings Plans are applied **before** Compute Savings Plans.

Savings Plans are applied to the highest savings percentage first. If there are multiple usages with equal savings
percentages, Savings Plans are applied to the first usage with the lowest Savings Plans rate.<br/>
Savings Plans continue to apply until there are no more remaining usages, or one's commitment is exhausted. Any
remaining usage is then charged at the On-Demand rates.

## Resource tagging

Suggested:

| Tag                     | Purpose | Example                                                         | Notes |
| ----------------------- | ------- | --------------------------------------------------------------- | ----- |
| `Name`                  | AWS UI  | `GitlabRunner`                                                  |       |
| `Owner`                 |         | `SecurityLead`, `SecOps`, `Workload-1-Development-team`         |       |
| `BusinessUnitId`        |         | `Finance`, `Retail`, `API-1`, `DevOps`                          |       |
| `Environment`           |         | `Sandbox`, `Dev`, `PreProd`, `QA`, `Prod`, `Testing`            |       |
| `CostCenter`            |         | `FIN123`, `Retail-123`, `Sales-248`, `HR-333`                   |       |
| `FinancialOwner`        |         | `HR`, `SecurityLead`, `DevOps-3`, `Workload-1-Development-team` |       |
| `ComplianceRequirement` |         | `NIST`, `HIPAA`, `GDPR`                                         |       |

[Create tag policies][creating organization policies with aws organizations] to enforce values, and to prevent the
creation of non-compliant resources.

## API

Refer [Tools to Build on AWS].

### Python

Refer [Boto3 documentation].<br/>
Also see [Difference in Boto3 between resource, client, and session?].

_Clients_ and _Resources_ are different abstractions for service requests within the Boto3 SDK.<br/>
When making API calls to an AWS service with Boto3, one does so via a _Client_ or a _Resource_.

_Sessions_ are fundamental to both Clients and Resources and how both get access to AWS credentials.

<details style="padding: 0 0 0 1em;">
  <summary>Client</summary>

Provides low-level access to AWS services by exposing the `botocore` client to the developer.

Typically maps 1:1 with the related service's API and supports all operations for the called service.<br/>
Exposes Python-fashioned method names (e.g. ListBuckets API => list_buckets method).

Typically yields primitive, non-marshalled AWS data.<br/>
E.g. DynamoDB attributes are dictionaries representing primitive DynamoDB values.

Limited to listing at most 1000 objects, requiring the developer to deal with result pagination in code.<br/>
Use a [paginator][boto3 paginators] or implement one's own loop.

  <details style="padding: 0 0 1em 1em;">
    <summary>Example</summary>

```py
import boto3

client = boto3.client('s3')
response = client.list_objects_v2(Bucket='mybucket')
for content in response['Contents']:
    obj_dict = client.get_object(Bucket='mybucket', Key=content['Key'])
    print(content['Key'], obj_dict['LastModified'])
```

  </details>
</details>

<details style="padding: 0 0 0 1em;">
  <summary>Resource</summary>

Refer [Boto3 resources].

Provides high-level, object-oriented code.

Does **not** provide 100% API coverage of AWS services.

Uses identifiers and attributes, has actions (operations on resources), and exposes sub-resources and collections of
AWS resources.

Typically yields marshalled data, **not** primitive AWS data.<br/>
E.g. DynamoDB attributes are native Python values representing primitive DynamoDB values.

Takes care of result pagination.<br/>
The resulting collections of sub-resources are lazily-loaded.

Resources are **not** thread safe and should **not** be shared across threads or processes.<br/>
Create a new Resource for each thread or process instead.

Since January 2023 the AWS Python SDK team stopped adding new features to the resources interface in Boto3.<br/>
Newer service features can be accessed through the Client interface.<br/>
Refer [More info about resource deprecation?] for more information.

  <details style="padding: 0 0 1em 1em;">
    <summary>Example</summary>

```py
import boto3

s3 = boto3.resource('s3')
bucket = s3.Bucket('mybucket')
for obj in bucket.objects.all():
    print(obj.key, obj.last_modified)
```

  </details>
</details>

<details style="padding: 0 0 1em 1em;">
  <summary>Session</summary>

Refer [Boto3 sessions].

Stores configuration information (primarily credentials and selected AWS Region).<br/>
Initiates the connectivity to AWS services.

Leveraged by service Clients and Resources.<br/>
boto3 creates a default session automatically when needed, using the default credential profile.<br/>
The default credentials profile uses the `~/.aws/credentials` file if found, or tries assuming the role of the executing
machine if not.

</details>

## Further readings

- [EC2]
- [Services that publish CloudWatch metrics]
- [Best Practices for Tagging AWS Resources]
- [Automating DNS-challenge based LetsEncrypt certificates with AWS Route 53]
- AWS' [CLI]
- [Tools to Build on AWS]
- [Boto3 documentation]
- [More info about resource deprecation?]

### Sources

- [Constraints for tags][constraints  tag]
- [What is CloudWatch]
- [What is Amazon VPC?]
- [Subnets for your VPC]
- [What is AWS Config?]
- [AWS Config tutorial by Stephane Maarek]
- [Date & time policy conditions at AWS - 1-minute IAM lesson]
- [Elastic IP addresses]
- [Test Your Roles' Access Policies Using the AWS Identity and Access Management Policy Simulator]
- [Exporting DB snapshot data to Amazon S3]
- [I'm trying to export a snapshot from Amazon RDS MySQL to Amazon S3, but I'm receiving an error. Why is this happening?]
- [Rotating AWS KMS keys]
- [Image baking in AWS using Packer and Image builder]
- [Using AWS KMS via the CLI with a Symmetric Key]
- [AWS Public IP Address Ranges Now Available in JSON Form]
- [Savings Plans user guide]
- [AWS Savings Plans Vs. Reserved Instances: When To Use Each]
- [How can I use AWS KMS asymmetric keys to encrypt a file using OpenSSL?]
- [A guide to tagging resources in AWS]
- [Guidance for Tagging on AWS]
- [Creating organization policies with AWS Organizations]
- [AWS re:Invent 2022 - Advanced VPC design and new Amazon VPC capabilities (NET302)]
- [Enable or disable AWS Regions in your account]
- [Difference in Boto3 between resource, client, and session?]
- [Boto3 resources]
- [Boto3 sessions]
- [Boto3 paginators]

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
[efs]: ecs.md
[eks]: eks.md
[iam]: iam.md
[opensearch]: opensearch.md
[rds]: rds.md
[route53]: route53.md
[s3]: s3.md
[sagemaker]: sagemaker.md
[sns]: sns.md
[sqs]: sqs.md

<!-- Upstream -->
[access aws services through aws privatelink]: https://docs.aws.amazon.com/vpc/latest/privatelink/privatelink-access-aws-services.html
[aws icons]: https://aws-icons.com/
[aws public ip address ranges now available in json form]: https://aws.amazon.com/blogs/aws/aws-ip-ranges-json/
[aws re:invent 2022 - advanced vpc design and new amazon vpc capabilities (net302)]: https://www.youtube.com/watch?v=cbUNbK8ZdA0&pp=ygUWYW1hem9uIGludmVudCAyMDIyIHZwYw%3D%3D
[best practices for tagging aws resources]: https://docs.aws.amazon.com/whitepapers/latest/tagging-best-practices/tagging-best-practices.html
[boto3 documentation]: https://boto3.amazonaws.com/v1/documentation/api/latest/index.html
[boto3 paginators]: https://boto3.amazonaws.com/v1/documentation/api/latest/guide/paginators.html
[boto3 resources]: https://boto3.amazonaws.com/v1/documentation/api/latest/guide/resources.html
[boto3 sessions]: https://boto3.amazonaws.com/v1/documentation/api/latest/guide/session.html
[connect to the internet using an internet gateway]: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html
[constraints  tag]: https://docs.aws.amazon.com/directoryservice/latest/devguide/API_Tag.html
[creating organization policies with aws organizations]: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_policies_create.html
[elastic ip addresses]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html
[enable or disable aws regions in your account]: https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-regions.html
[exporting db snapshot data to amazon s3]: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ExportSnapshot.html
[guidance for tagging on aws]: https://aws.amazon.com/solutions/guidance/tagging-on-aws/
[how can i use aws kms asymmetric keys to encrypt a file using openssl?]: https://repost.aws/knowledge-center/kms-openssl-encrypt-key
[i'm trying to export a snapshot from amazon rds mysql to amazon s3, but i'm receiving an error. why is this happening?]: https://repost.aws/knowledge-center/rds-mysql-export-snapshot
[more info about resource deprecation?]: https://github.com/boto/boto3/discussions/3563
[nat gateways]: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html
[rotating aws kms keys]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html
[savings plans user guide]: https://docs.aws.amazon.com/savingsplans/latest/userguide/
[services that publish cloudwatch metrics]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html
[subnets for your vpc]: https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html
[test your roles' access policies using the aws identity and access management policy simulator]: https://aws.amazon.com/blogs/security/test-your-roles-access-policies-using-the-aws-identity-and-access-management-policy-simulator/
[tools to build on aws]: https://aws.amazon.com/developer/tools/
[what is amazon vpc?]: https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html
[what is aws config?]: https://docs.aws.amazon.com/config/latest/developerguide/WhatIsConfig.html
[what is cloudwatch]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html

<!-- Others -->
[a guide to tagging resources in aws]: https://medium.com/@staxmarketing/a-guide-to-tagging-resources-in-aws-8f4311afeb46
[automating dns-challenge based letsencrypt certificates with aws route 53]: https://johnrix.medium.com/automating-dns-challenge-based-letsencrypt-certificates-with-aws-route-53-8ba799dd207b
[aws config tutorial by stephane maarek]: https://www.youtube.com/watch?v=qHdFoYSrUvk
[aws savings plans vs. reserved instances: when to use each]: https://www.cloudzero.com/blog/savings-plans-vs-reserved-instances/
[date & time policy conditions at aws - 1-minute iam lesson]: https://www.youtube.com/watch?v=4wpKP1HLEXg
[difference in boto3 between resource, client, and session?]: https://stackoverflow.com/questions/42809096/difference-in-boto3-between-resource-client-and-session
[image baking in aws using packer and image builder]: https://dev.to/santhoshnimmala/image-baking-in-aws-using-packer-and-image-builder-1ed3
[using aws kms via the cli with a symmetric key]: https://nsmith.net/aws-kms-cli
