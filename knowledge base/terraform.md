# Terraform

1. [TL;DR](#tldr)
1. [Modules](#modules)
   1. [Useful internal variables](#useful-internal-variables)
1. [Versioning](#versioning)
1. [Troubleshooting](#troubleshooting)
   1. [`count` vs `for_each`](#count-vs-for_each)
   1. [Conditional creation of a resource](#conditional-creation-of-a-resource)
   1. [Force the recreation of specific resources](#force-the-recreation-of-specific-resources)
   1. [Error: at least 1 "features" blocks are required](#error-at-least-1-features-blocks-are-required)
   1. [Add/subtract time](#addsubtract-time)
   1. [Export the contents of a tfvars file as shell variables](#export-the-contents-of-a-tfvars-file-as-shell-variables)
   1. [Print sensitive values in output](#print-sensitive-values-in-output)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Initialization.
terraform init
terraform init -reconfigure

# Validate files.
terraform validate

# Show what would be done.
terraform plan
terraform plan -state 'path/to/file.tfstate' -var-file 'path/to/var.tfvars'
terraform plan -out 'path/to/file.tfstate' -parallelism '50'

# Make the changes.
terraform apply
terraform apply -auto-approve -backup -parallelism '25' 'path/to/plan.tfstate'

# Destroy everything.
# `destroy` is an alias of `apply -destroy` and is being deprecated.
terraform destroy
terraform apply -destroy

# Unlock a state file.
terraform force-unlock 'lock_id'

# Format files.
terraform fmt
terraform fmt -check -diff -recursive

# Show outputs.
terraform output 'team_tokens'

# List registered resource.
terraform state list

# Show registered resources' details.
terraform state show 'packet_device.worker'
terraform state show 'packet_device.worker["example"]'
terraform state show 'module.foo.packet_device.worker'

# Remove registered resources from states.
terraform state rm 'oci_core_instance.ampere'
terraform state -state 'path/to/file.tfstate' \
  'module.foo.packet_device.worker' 'tfe_team.robots[1]'

# Remove all resources from the current state.
terraform state list | xargs terraform state rm

# Import existing resources into the state.
terraform import 'oci_core_instance.this' 'ocid1.instance.oc1…'
terraform import 'tfe_team.robots[4]' 'team-KV54…'
terraform import 'module.app42.google_sql_user.teams["secops"]' 'fizzybull/…'

# Show all the existing resources.
terraform show
terraform show -json

# Create a dependency graph.
# Requires `dot` from 'graphviz' for image generation.
terraform graph
terraform graph | dot -Tsvg > 'graph.svg'

# Recursively update all modules.
# `get` is being deprecated in favour of `init`
terraform get -update -no-color
```

## Modules

Include a module in the configuration with the `module` keyword:

```hcl
module "remote_vpc_module" {

  # module settings
  source  = "terraform-aws-modules/vpc/aws"  # required
  version = "2.21.0"

  # module variables
  …

}

module "local_vpc_module" {

  # module settings
  source = "./modules/aws_vpc"  # required

  # module variables
  …

}
```

Run `terraform init` or `terraform get` to install the modules.  
Modules are installed in the `.terraform/modules` directory inside the configuration's working directory; local modules are symlinked from there.

When terraform processes a module block, that block will inherit the provider from the enclosing configuration.

A module's output can be accessed from the configuration that calls the module through the syntax `module.$moduleName.$outputName`. Module outputs are read-only attributes.

### Useful internal variables

Name                  | Description
--------------------- | -----------
`path.root`           | filesystem path of the root module of the configuration
`path.module`         | filesystem path of the module where the expression is placed
`path.cwd`            | filesystem path of the current working directory
`terraform.workspace` | name of the currently selected workspace

## Versioning

Use a _string_ literal containing one or more conditions separated by commas:

```ini
version = ">= 1.2.0, < 2.0.0"
version = "~> 1.3, < 1.9.5"
```

Each condition must consist of an operator and a version number. The available operators are as follow:

Operator             | Description
-------------------- | -----------
`=` or not present   | Specify the **exact** version number. It cannot be combined with other conditions.
`!=`                 | Exclude the **exact** version number.
`>`, `>=`, `<`, `<=` | Compare the available versions against the one specified and allow those for which the comparison is true.
`~>`                 | Allow only the **rightmost** version component to be incremented.

## Troubleshooting

### `count` vs `for_each`

`count` creates an unordered list of objects, while `for_each` creates a map.

`count` is sensitive to any changes in the list order and this means that if for some reason order of the list is changed terraform will force the replacement of all resources for which the index in the list has changed:

```diff
variable "my_list" {
-  default = ["first", "second", "third"]
+  default = ["zeroth", "first", "second", "third"]
}
```

```txt
Terraform will perform the following actions:

# null_resource.default[0] must be replaced
-/+ resource "null_resource" "default" {
      ~ id       = "4074861383382414527" -> (known after apply)
      ~ triggers = { # forces replacement
            "list_index" = "0"
          ~ "list_value" = "first" -> "zeroth"
        }
    }
…
# null_resource.default[3] will be created
  + resource "null_resource" "default" {
      + id       = (known after apply)
      + triggers = {
          + "list_index" = "3"
          + "list_value" = "third"
        }
    }
```

### Conditional creation of a resource

You can conditionally create one or more resources.  
There are 2 ways to do this:

- with `count`:

  ```hcl
  resource "cloudflare_record" "record" {
    count = var.cloudflare_enabled ? 1 : 0
    …
  }
  ```

- with `for_each`:

  ```hcl
  resource "cloudflare_record" "record" {
    for_each = length(var.cloudflare_records_map) > 0 ? var.cloudflare_records_map : {}
    …
  }
  ```

Mind the type of object in the line, and the gotchas for each method.

### Force the recreation of specific resources

Use the `-replace=resource_path` option during a `plan` or `apply`:

```sh
terraform apply -replace=aws_instance.example
```

```txt
# aws_instance.example will be replaced, as requested
-/+ resource "aws_instance" "example" {
      …
    }
```

### Error: at least 1 "features" blocks are required

The `azurerm` provider needs to be configured with at least the following lines:

```hcl
provider "azurerm" {
  features {}
}
```

### Add/subtract time

Instead of using the `timeadd()` function, it is advisable to use the `time_offset` resource:

```hcl
resource "time_offset" "one_year_from_now" {
  offset_years = 1
}
resource "azurerm_key_vault_key" "key" {
  expiration_date = time_offset.one_year_from_now.rfc3339
  …
}
```

### Export the contents of a tfvars file as shell variables

```sh
# As normal shell variables.
eval "export $(sed -E 's/[[:blank:]]*//g' file.tfvars)"

# As TF shell variables (TF_VAR_*).
eval "export $(sed -E 's/([[:graph:]]+)[[:blank:]]*=[[:blank:]]*([[:graph:]]+)/TF_VAR_\1=\2/' file.tfvars)"
```

### Print sensitive values in output

1. Set the `sensitive` flag in the output definition, since it is required anyways:

   ```hcl
   output "team_tokens" {
     value     = { for key, team in … : key => team.token }
     sensitive = true
   }
   ```

1. Call `terraform output` specifying that output's identifier:

   ```sh
   $ terraform output 'team_tokens'
   {
     "team1" = "5aaH5674…"
     "test_team" = "543aH56f…"
   }
   ```

## Further readings

- [CLI Documentation]
- [Providers best practices]
- [Version constraints]
- [References to Named Values]
- [Environment Variables]
- [Forcing Re-creation of Resources]

[cli documentation]: https://www.terraform.io/docs/cli/
[environment variables]: https://www.terraform.io/cli/config/environment-variables
[forcing re-creation of resources]: https://www.terraform.io/cli/state/taint
[providers best practices]: https://www.terraform.io/language/providers/requirements#best-practices-for-provider-versions
[references to named values]: https://www.terraform.io/language/expressions/references
[version constraints]: https://www.terraform.io/language/expressions/version-constraints

## Sources

- [for_each vs count]
- [Azure Provider]
- [Conditional creation of a resource based on a variable in .tfvars]

[azure provider]: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
[conditional creation of a resource based on a variable in .tfvars]: https://stackoverflow.com/questions/60231309/terraform-conditional-creation-of-a-resource-based-on-a-variable-in-tfvars
[for_each vs count]: https://medium.com/@business_99069/terraform-count-vs-for-each-b7ada2c0b186
