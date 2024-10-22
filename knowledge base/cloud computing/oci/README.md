# Oracle Cloud Infrastructure

1. [Concepts](#concepts)
   1. [Compartments](#compartments)
   1. [Networking](#networking)
      1. [Access to the Internet](#access-to-the-internet)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Concepts

### Compartments

Compartments are tenancy-wide and extend across regions.<br/>
They can be nested to create hierarchies up to 6 levels deep.

After creating a compartment, one needs to write at least one (access) policy for it; until then, no one can access it
but administrators or users with permissions at the _tenancy_ level.<br/>
When creating sub-compartments, users inherit access permissions from compartments higher up their hierarchy.

Before deleting a compartment, all resources in it **must** have been moved, deleted or terminated.<br/>
This includes **any policies** attached to the compartment itself.

### Networking

#### Access to the Internet

| Resource         | Used for                                                                                           | Free-tier limit   |
| ---------------- | -------------------------------------------------------------------------------------------------- | ----------------- |
| Internet Gateway | **public** resources that need to **be** reach**ed** from the internet                             | ?                 |
| NAT Gateway      | resources that **need to reach** the internet but **are not reachable from** the internet          | 0 (not available) |
| Bastion          | resources that require Secure Shell (SSH) access but otherwise are not reachable from the internet | 5                 |

## Further readings

- [`oci-cli`][oci-cli]
- [Compute images]
- [Connect to private compute instances using OCI Bastion Service]
- [Running Commands on an Instance]

### Sources

- [Required keys and OCIDs]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[oci-cli]: oci-cli.md

<!-- Upstream -->
[compute images]: https://docs.oracle.com/en-us/iaas/images/
[required keys and ocids]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm

<!-- Others -->
[connect to private compute instances using oci bastion service]: https://medium.com/@harjulthakkar/connect-to-private-compute-instance-using-oci-bastion-service-ca96a3ceea49
[running commands on an instance]: https://docs.public.oneportal.content.oci.oraclecloud.com/en-us/iaas/Content/Compute/Tasks/runningcommands.htm
