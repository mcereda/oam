# Oracle Cloud

1. [Concepts](#concepts)
   1. [Compartments](#compartments)
2. [Further readings](#further-readings)
3. [Sources](#sources)

## Concepts

### Compartments

Compartments are tenancy-wide and extend across regions. They can also be nested to create hierarchies up to 6 levels deep.

After creating a compartment, you need to write at least one policy for it; until then, no one can access it except administrators or users who have permissions set at the tenancy level. When creating sub-compartments, they inherit access permissions from compartments higher up their hierarchy.

Before deleting a compartment, all its resources must have been moved, deleted or terminated, including any policies attached to the compartment itself.

## Further readings

- [oci-cli]
- [compute images]

## Sources

- [Required keys and OCIDs]

<!-- oracle cloud's documentation -->
[compute images]: https://docs.oracle.com/en-us/iaas/images/
[required keys and ocids]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm

<!-- internal references -->
[oci-cli]: ./oci-cli.md

<!-- external references -->
