# Sagemaker

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

- Endpoint Configurations depend on a Model.<br/>
  They are deleted if the Model they depend on changes.
- Serverless Endpoints' backend use **a snapshot** of the Endpoint Configuration at the time each host is created.<br/>
  To make a serverless Endpoint use a new Configuration or Model, its hosts need to be replaced.

## Further readings

- [Amazon Web Services]

### Sources

- [Give SageMaker AI Access to Resources in your Amazon VPC]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[amazon web services]: README.md

<!-- Files -->
<!-- Upstream -->
[Give SageMaker AI Access to Resources in your Amazon VPC]: https://docs.aws.amazon.com/sagemaker/latest/dg/infrastructure-give-access.html

<!-- Others -->
