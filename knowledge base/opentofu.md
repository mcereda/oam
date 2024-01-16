# OpenTofu

Open-source and community-driven fork of [Terraform] managed by the Linux Foundation.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Installation.
brew install 'opentofu'

# Manage autocompletion.
# Only supports BASH and ZSH.
tofu -install-autocomplete
tofu -uninstall-autocomplete

# Initialization.
tofu init
tofu init -reconfigure
tofu init -backend=false

# Validate files.
tofu validate
tofu validate -json -no-color

# Show what would be done.
tofu plan
tofu plan -state 'path/to/file.tfstate' -var-file 'path/to/var.tfvars'
tofu plan -out 'path/to/file.tfstate' -parallelism '50'

# Make the changes.
tofu apply
tofu apply -auto-approve -backup -parallelism '25' 'path/to/plan.tfstate'
tofu -chdir='envs/prod' apply …

# Destroy everything.
# `destroy` is an alias of `apply -destroy` and is being deprecated.
tofu destroy
tofu apply -destroy

# Unlock a state file.
tofu force-unlock 'lock_id'

# Format files.
tofu fmt
tofu fmt -check -diff -recursive

# Show outputs.
tofu output 'team_tokens'

# List registered resource.
tofu state list

# Show registered resources' details.
tofu state show 'packet_device.worker'
tofu state show 'packet_device.worker["example"]'
tofu state show 'module.foo.packet_device.worker'

# Remove registered resources from states.
tofu state rm 'oci_core_instance.ampere'
tofu state -state 'path/to/file.tfstate' \
  'module.foo.packet_device.worker' 'tfe_team.robots[1]'

# Remove all resources from the current state.
tofu state list | xargs tofu state rm

# Import existing resources into the state.
tofu import 'oci_core_instance.this' 'ocid1.instance.oc1…'
tofu import 'tfe_team.robots[4]' 'team-KV54…'
tofu import 'module.app42.google_sql_user.teams["secops"]' 'fizzybull/…'

# Show all the existing resources.
tofu show
tofu show -json

# Create a dependency graph.
# Requires `dot` from 'graphviz' for image generation.
tofu graph
tofu graph | dot -Tsvg > 'graph.svg'

# Recursively update all modules.
# `get` is being deprecated in favour of `init`
tofu get -update -no-color

# Do stuff in the console in a non-interactive way.
echo 'split(",", "foo,bar,baz")' | tofu console
```

## Further readings

- [Website]
- [Documentation]
- [Terraform]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[terraform]: terraform.md

<!-- Upstream -->
[documentation]: https://opentofu.org/docs/
[website]: https://opentofu.org/
