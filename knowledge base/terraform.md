# Terraform

## TL;DR

```shell
# init
terraform init
terraform init -reconfigure

# check what would be done
terraform plan
terraform plan -out path/to/file.tfstate -parallelism 50

# make the changes
terraform apply
terraform apply -auto-approve -backup -parallelism 25 path/to/plan.tfstate

# destroy everything
terraform destroy

# check files formatting
terraform fmt
terraform fmt -check -diff -recursive

# validate files
terraform validate

# create a graph
# requires dot from graphviz for image generation
terraform graph
terraform graph | dot -Tsvg > graph.svg

# show a created resource
terraform state show 'packet_device.worker'
terraform state show 'packet_device.worker["example"]'
terraform state show 'module.foo.packet_device.worker'

# recursively update all needed modules
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

## Gotchas

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

### Useful internal variables

Name                  | Description
--------------------- | -----------
`path.root`           | filesystem path of the root module of the configuration
`path.module`         | filesystem path of the module where the expression is placed
`path.cwd`            | filesystem path of the current working directory
`terraform.workspace` | name of the currently selected workspace

## Further readings

- [CLI Documentation]
- [for_each vs count]
- [Providers best practices]
- [Version constraints]
- [References to Named Values]


[cli documentation]: https://www.terraform.io/docs/cli/
[providers best practices]: https://www.terraform.io/language/providers/requirements#best-practices-for-provider-versions
[references to named values]: https://www.terraform.io/language/expressions/references
[version constraints]: https://www.terraform.io/language/expressions/version-constraints

[for_each vs count]: https://medium.com/@business_99069/terraform-count-vs-for-each-b7ada2c0b186
