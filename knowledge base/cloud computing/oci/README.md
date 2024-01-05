# Oracle Cloud Infrastructure

## Table of contents <!-- omit in toc -->

1. [Concepts](#concepts)
   1. [Compartments](#compartments)
   1. [Networking](#networking)
      1. [Access to the Internet](#access-to-the-internet)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Concepts

### Compartments

Compartments are tenancy-wide and extend across regions. They can also be nested to create hierarchies up to 6 levels deep.

After creating a compartment, you need to write at least one policy for it; until then, no one can access it except administrators or users who have permissions set at the tenancy level. When creating sub-compartments, they inherit access permissions from compartments higher up their hierarchy.

Before deleting a compartment, all its resources must have been moved, deleted or terminated, including any policies attached to the compartment itself.

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

## Sources

All the references in the [further readings] section, plus the following:

- [Required keys and OCIDs]

<!--
  References
  -->

<!-- In-article sections -->
[oci-cli]: oci-cli.md

<!-- Upstream -->
[compute images]: https://docs.oracle.com/en-us/iaas/images/
[required keys and ocids]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm

<!-- Others -->
[connect to private compute instances using oci bastion service]: https://medium.com/@harjulthakkar/connect-to-private-compute-instance-using-oci-bastion-service-ca96a3ceea49
