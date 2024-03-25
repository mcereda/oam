# Amazon Web Services

1. [Services](#services)
   1. [CloudWatch](#cloudwatch)
1. [Resource constraints](#resource-constraints)
1. [Access control](#access-control)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Services

| Service      | Description                                   |
| ------------ | --------------------------------------------- |
| [CloudWatch] | Observability (logging, monitoring, alerting) |
| [EC2]        | Virtual machines                              |

### CloudWatch

Observability service. with functions for logging, monitoring and alerting.

_Metrics_ are whatever needs to be monitored (e.g. CPU usage). _Data points_ are the values of a metric over time.
_Namespaces_ are containers for metrics.

Metrics only exist in the region in which they are created.

[Many AWS services][services that publish cloudwatch metrics] offer basic monitoring by publishing a default set of metrics to CloudWatch with no charge.<br/>
This feature is automatically enabled by default when one starts using one of these services.

## Resource constraints

| data type | component | summary                       | description                                                                                                                                                                                                                                                | type   | length   | pattern                           | required |
| --------- | --------- | ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | -------- | --------------------------------- | -------- |
| tag       | key       | Required name of the tag      | The string value can be Unicode characters and cannot be prefixed with "aws:".<br/>The string can contain only the set of Unicode letters, digits, white-space, `_`,' `.`, `/`, `=`, `+`, `-`, `:`, `@` (Java regex: `^([\\p{L}\\p{Z}\\p{N}_.:/=+\\-]*)$`) | String | 1 to 128 | `^([\p{L}\p{Z}\p{N}_.:/=+\-@]*)$` | Yes      |
| tag       | value     | The optional value of the tag | The string value can be Unicode characters. The string can contain only the set of Unicode letters, digits, white-space, `_`, `.`, `/`, `=`, `+`, `-`, `:`, `@` (Java regex: `^([\\p{L}\\p{Z}\\p{N}_.:/=+\\-]*)$"`)                                        | String | 0 to 256 | `^([\p{L}\p{Z}\p{N}_.:/=+\-@]*)$` | Yes      |

## Access control

From [Using service-linked roles]:

> A _service role_ is an IAM role that a service assumes to perform actions on your behalf.<br/>
> An IAM administrator can create, modify, and delete a service role from within IAM.
>
> A _service-linked role_ is a type of service role that is linked to an AWS service.<br/>
> The service can assume the role to perform an action on your behalf.<br/>
> Service-linked roles appear in your AWS account and are owned by the service. An IAM administrator can view, but not edit the permissions for service-linked roles.

## Further readings

- [EC2]
- [Services that publish CloudWatch metrics]
- [Using service-linked roles]
- [Best Practices for Tagging AWS Resources]

### Sources

- [Constraints for tags][constraints  tag]
- [What is cloudWatch]

<!--
  References
  -->

<!-- In-article sections -->
[cloudwatch]: #cloudwatch

<!-- Knowledge base -->
[ec2]: ec2.md

<!-- Upstream -->
[best practices for tagging aws resources]: https://docs.aws.amazon.com/whitepapers/latest/tagging-best-practices/tagging-best-practices.html
[constraints  tag]: https://docs.aws.amazon.com/directoryservice/latest/devguide/API_Tag.html
[services that publish cloudwatch metrics]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html
[using service-linked roles]: https://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html
[what is cloudwatch]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html
