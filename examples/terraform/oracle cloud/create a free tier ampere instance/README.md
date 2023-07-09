# Oracle free tier Ampere VM

Simple example to create an Ampere VM instance in Oracle Cloud's free tier.

## Table of contents <!-- omit in toc -->

1. [Requirements](#requirements)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Requirements

1. VCN
1. **Public** Subnet

For a Subnet to be considered Public, it needs to have associated a Route Table with a default route pointing to an Internet Gateway.

The default route table created using Terraform does not contain this route, nor it is possible to create the single route in it at the time of writing.<br />
A solution to this is to create a new Route Table **with** the default route above and attach it to the Subnet. See the code for details.

![requirements]

## Further readings

- [Ridiculously powerful free server in the cloud]

## Sources

All the references in the [further readings] section, plus the following:

- [Always free resources] in Oracle Cloud
- [Oracle Cloud Infrastructure Provider documentation]
- [oracle-terraform-modules/terraform-oci-compute-instance]

<!--
  References
  -->

<!-- Upstream -->
[always free resources]: https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm
[oracle cloud infrastructure provider documentation]: https://registry.terraform.io/providers/oracle/oci/latest/docs
[oracle-terraform-modules/terraform-oci-compute-instance]: https://github.com/oracle-terraform-modules/terraform-oci-compute-instance

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Files -->
[requirements]: design/requirements.png

<!-- Others -->
[ridiculously powerful free server in the cloud]: https://medium.com/codex/ridiculously-powerful-free-server-in-the-cloud-dd4da8524a9c
