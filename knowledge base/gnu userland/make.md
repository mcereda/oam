# GNU Make

1. [TL;DR](#tldr)
1. [Load .env files in the Makefile](#load-env-files-in-the-makefile)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```makefile
# assign default values, but allow override
# usage: make override_me=new_value target
override override_me ?= default_value


# Load env files.
# If prefixed with '-' it does not error should any of the files not exist.
include .env
-include .env.local .env.extra


# export variables for all programs to see
# only exported in the commands' sub-shells
export

# export specific variables only
export override_me


# assign shell command output as values
command_output = ${shell command with args}


target_name: target_specific_variable = value
target_name: dash_instead_of_underscore = ${subst _,-,${override_me}}
target_name: previous_target required_file.ext
    ${info output string}
    echoed_command
    @quiet_command
    ${MAKE} next_target

previous_target:
    @quiet_command

next_target:


# conditionals
ifeq "${shell uname}" "Darwin"
expiration_date = ${shell date -v "+365d" "+%FT%TZ"}
else ifeq "${shell uname}" "Linux"
expiration_date = ${shell date -d "+1 year" "+%FT%TZ"}
endif
```

```makefile
repository_name = $(shell basename $$(git rev-parse --show-toplevel))

override environment_id ?= dev
override tf_plan_file ?= ${environment_id}.tfplan
override tf_vars_file ?= ${environment_id}.tfvars

-include .env
export

pre-flight:
    ${info validating terraform's configuration…}
    @terraform fmt -recursive
    @terraform validate

ifeq "${destroy}" "1"
tf_destroy_switch = -destroy
endif

plan: pre-flight ${tf_vars_file}
    ${info planning ${environment_id}'s resources…}
    @terraform plan ${tf_destroy_switch} -var-file='${tf_vars_file}' -input=false -out='${tf_plan_file}'

apply: plan ${tf_plan_file}
    ${info applying ${environment_id}'s plan}
    @terraform apply '${tf_plan_file}'
```

## Load .env files in the Makefile

Use one of those at the top of a Makefile to include and make available all variables in `.env`:

```makefile
include .env
-include .env.local .env.extra
```

```makefile
ifneq (,$(wildcard ./.env))
  include .env
  export
endif
```

`ifneq` + `wildcard` is a typical way to check a file exists.

`include .env` imports `.env` into the Makefile variables.<br/>
If prefixed with '-' (`-include`), it does not error nor warning should any of the included files not exist.

`export` without parameters exports all variables set until now.

## Further readings

- [Conditional syntax]
- [Include]

### Sources

- [Makefile variable initialization and export]
- [How to load and export variables from an .env file in Makefile?]

<!--
  References
  -->

<!-- Upstream -->
[conditional syntax]: https://www.gnu.org/software/make/manual/html_node/Conditional-Syntax.html
[include]: https://www.gnu.org/software/make/manual/html_node/Include.html

<!-- Others -->
[how to load and export variables from an .env file in makefile?]: https://stackoverflow.com/questions/44628206/how-to-load-and-export-variables-from-an-env-file-in-makefile#70663753
[makefile variable initialization and export]: https://stackoverflow.com/questions/2838715/makefile-variable-initialization-and-export
