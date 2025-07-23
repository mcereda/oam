# RoleOut

Project trying to accelerate the design and deployment of Snowflake environments through Infrastructure as Code.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

Administrators define Snowflake resources in a YAML file. RoleOut then uses it to generate SQL or Terraform code for
deployment.

> [!important]
> The tool applies opinionated best practices.<br/>
> It also comes with its own naming convention, but it can be tweaked.

<details>
  <summary>Setup</summary>

```sh
# Mac OS X
curl -C '-' -LfSO --url 'https://github.com/Snowflake-Labs/roleout/releases/download/v2.0.1/Roleout-2.0.1-arm64.dmg' \
&& sudo installer -pkg 'Roleout-2.0.1-arm64.dmg' -target '/' \
&& sudo xattr -r -d 'com.apple.quarantine' '/Applications/Roleout.app' \
&& curl -C '-' -LfS --url 'https://github.com/Snowflake-Labs/roleout/releases/download/v2.0.1/roleout-cli-macos' \
     --output "$HOME/bin/roleout-cli" \
&& chmod 'u+x' "$HOME/bin/roleout-cli" \
&& xattr -d 'com.apple.quarantine' "$HOME/bin/roleout-cli"

# Configure access
export SNOWFLAKE_ACCOUNT='ab01234.eu-west-1' \
  SNOWFLAKE_USER='DIANE' SNOWFLAKE_PRIVATE_KEY_PATH='some-private-key-path' \
  SNOWFLAKE_WAREHOUSE='DEV_DIANE_WH' SNOWFLAKE_ROLE='ACCOUNTADMIN'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Load objects from Snowflake
roleout-cli snowflake populateProject -o 'my_config.yml'

# Update existing configurations
roleout-cli snowflake populateProject -c 'my_config.yml' -o 'my_new_config.yml'

# Import existing objects that are defined in the configuration
roleout-cli terraform import -c 'my_config.yml'
# Just write the `terraform import` commands to a file instead of running them
roleout-cli terraform import -c 'my_config.yml' --output 'my_import_commands.sh'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Snowflake]
- [Codebase]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Snowflake]: README.md

<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/Snowflake-Labs/roleout

<!-- Others -->
