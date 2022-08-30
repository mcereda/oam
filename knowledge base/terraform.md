# Terraform

## TL;DR

```sh
# Initialization.
terraform init
terraform init -reconfigure

# Validate files.
terraform validate

# Show what would be done.
terraform plan
terraform plan -out path/to/file.tfstate -parallelism 50

# Make the changes.
terraform apply
terraform apply -auto-approve -backup -parallelism 25 path/to/plan.tfstate

# Destroy everything.
# `destroy` is an alias of `apply -destroy` and is being deprecated.
terraform destroy
terraform apply -destroy

# Format files.
terraform fmt
terraform fmt -check -diff -recursive

# Create a dependency graph.
# Requires `dot` from 'graphviz' for image generation.
terraform graph
terraform graph | dot -Tsvg > graph.svg

# Show an existing resource.
terraform state show 'packet_device.worker'
terraform state show 'packet_device.worker["example"]'
terraform state show 'module.foo.packet_device.worker'

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

```text
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

### At least 1 "features" blocks are required

The `azurerm` provider needs to be configured with at least the following lines:

```hcl
provider "azurerm" {
  features {}
}
```

## Further readings

- [CLI Documentation]
- [Providers best practices]
- [Version constraints]
- [References to Named Values]

[cli documentation]: https://www.terraform.io/docs/cli/
[providers best practices]: https://www.terraform.io/language/providers/requirements#best-practices-for-provider-versions
[references to named values]: https://www.terraform.io/language/expressions/references
[version constraints]: https://www.terraform.io/language/expressions/version-constraints

## Sources

- [for_each vs count]
- [Azure Provider]

[for_each vs count]: https://medium.com/@business_99069/terraform-count-vs-for-each-b7ada2c0b186
[azure provider]: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
