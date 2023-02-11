# Oracle Bastion

Simple example to create a Bastion in Oracle Cloud.

1. [Requirements](#requirements)
2. [SSH configuration](#ssh-configuration)
3. [Further readings](#further-readings)
4. [Sources](#sources)

## Requirements

1. VCN
1. **Private** Subnet
1. **RSA** SSH key

For a Subnet to be considered Private, it needs to have associated a Route Table with a default route pointing to a NAT Gateway.

> **Note:** NAT Gateways are not included in Oracle's free tier.

The default route table created using Terraform does not contain this route, nor it is possible to create the single route in it at the time of writing.<br />
A solution to this is to create a new Route Table **with** the default route above and attach it to the Subnet. See the code for details.

![requirements]

## SSH configuration

```ssh_config
Host  bastion
  Hostname                  host.bastion.eu-amsterdam-1.oci.oraclecloud.com
  HostkeyAlgorithms         +ssh-rsa
  PubkeyAcceptedAlgorithms  +ssh-rsa
  LocalForward              8022 10.0.0.230:22
  User                      ocid1.bastionsession.oc1.eu-amsterdam-1.amaaaaaazsnap6iazqwiktq2b7i736d5cgc2vnswuypa3iey754rlj4yyrvq

Host  instance
  Hostname  localhost
  User      opc
  Port      8022

Host  bastion instance
  IdentityFile           ~/.ssh/id_rsa
  IdentitiesOnly         yes
  StrictHostKeyChecking  no
  UserKnownHostsFile     /dev/null
```

## Further readings

## Sources

- [Ridiculously powerful free server in the cloud]
- [Always free resources] in Oracle Cloud
- [Oracle Cloud Infrastructure Provider documentation]
- [oracle-terraform-modules/terraform-oci-compute-instance]

<!-- internal references -->
[requirements]: design/requirements.png

<!-- external references -->
[always free resources]: https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm
[oracle cloud infrastructure provider documentation]: https://registry.terraform.io/providers/oracle/oci/latest/docs
[ridiculously powerful free server in the cloud]: https://medium.com/codex/ridiculously-powerful-free-server-in-the-cloud-dd4da8524a9c
[oracle-terraform-modules/terraform-oci-compute-instance]: https://github.com/oracle-terraform-modules/terraform-oci-compute-instance
