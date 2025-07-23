# Snowflake CLI

Refer [Snowflake CLI].

Meant to replace the SnowSQL tool.

1. [TL;DR](#tldr)
1. [Setup](#setup)
1. [Usage](#usage)
1. [Further readings](#further-readings)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Using Homebrew
brew install 'snowflake-cli'
# Get it from the [Snowflake CLI repository]
curl --continue-at '-' --location --fail --show-error --remote-name \
  --url 'https://sfc-repo.snowflakecomputing.com/snowflake-cli/linux_aarch64/3.7.2/snowflake-cli-3.7.2.aarch64.deb' \
&& sudo dpkg -i 'snowflake-cli-3.7.2.aarch64.deb'
curl --continue-at '-' --location --fail --show-error --remote-name \
  --url 'https://sfc-repo.snowflakecomputing.com/snowflake-cli/linux_aarch64/3.7.2/snowflake-cli-3.7.2.aarch64.rpm' \
&& sudo rpm -i 'snowflake-cli-3.7.2.rpm'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Check it works.
snow --version

# Get help.
snow --help
snow helpers -h

# List configured connections to Snowflake.
snow connection list

# Add connections.
snow connection add

# Test connections.
snow connection test
snow connection test -c 'connection-name'

# Executes Snowflake queries.
snow sql
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Setup

Install the package from the [Snowflake CLI repository].

<details style='padding: 0 0 1rem 1rem'>

```sh
# Linux
# DEB
curl --continue-at '-' --location --fail --show-error --remote-name \
  --url 'https://sfc-repo.snowflakecomputing.com/snowflake-cli/linux_aarch64/3.7.2/snowflake-cli-3.7.2.aarch64.deb' \
&& sudo dpkg -i 'snowflake-cli-3.7.2.aarch64.deb'
# RPM
curl --continue-at '-' --location --fail --show-error --remote-name \
  --url 'https://sfc-repo.snowflakecomputing.com/snowflake-cli/linux_aarch64/3.7.2/snowflake-cli-3.7.2.aarch64.rpm' \
&& sudo rpm -i 'snowflake-cli-3.7.2.rpm'

# Mac OS X
# Via Homebrew
brew install 'snowflake-cli'
# Via the [Snowflake CLI repository]
curl --continue-at '-' --location --fail --show-error --remote-name \
  --url 'https://sfc-repo.snowflakecomputing.com/snowflake-cli/darwin_arm64/3.7.2/snowflake-cli-3.7.2-darwin-arm64.pkg' \
&& sudo installer -pkg 'snowflake-cli-3.7.2-darwin-arm64.pkg' -target '/' \
&& ln -swiv '/Applications/SnowflakeCLI.app/Contents/MacOS/snow' "$HOME/bin/snow"
```

</details>

Refer [Configuring Snowflake CLI] and [Managing Snowflake connections] for the configuration.

Snowflake CLI uses a global configuration file to configure connections and logs.<br/>
The CLI looks for:

- The file specified by the `--config-file` option.
- A `config.toml` file in the location specified by the `SNOWFLAKE_HOME` environment variable, if set.
- The `~/.snowflake/config.toml` file, if such directory exists.
- The `config.toml` file in the one of the following locations, based on one's operating system:

  - Linux: `$XDG_CONFIG_HOME/snowflake/config.toml`.
  - Windows: `%USERPROFILE%\AppData\Local\snowflake\config.toml`
  - Mac OS X: `~/Library/Application Support/snowflake/config.toml`

If the global configuration file does not exist, running any `snow` command for the first time automatically creates an
empty `config.toml` file that one can then populate with the desired connections.

For MacOS and Linux systems, Snowflake CLI requires the configuration file to limit its file permissions to read and
write for the file owner only.

```sh
chown "$USER" "$HOME/.snowflake/config.toml"
chmod 'u=rw,go=' "$HOME/.snowflake/config.toml"
```

The configuration supports the following sections:

- `[connections]`, for defining and managing connections.
- `[logs]`, for configuring which types of messages are saved to log files.

A configuration file has the following structure:

```toml
[cli.logs]
save_logs = true
level = "info"
path = "/home/john/.snowflake/logs"

[connections.default]
account = "ABCDEFG-YZ01234"
user = "JDOE"
password = "SuperSecur3Pa$$word"
authenticator = "externalbrowser"
role = "PROD_SYSTEM_FR"
```

One can generate the basic settings for the TOML configuration file in Snowsight.

> [!important]
> Should a `connection.toml` file exist in the same directory as the global configuration file, Snowflake CLI will use
> the connections defined there instead of the ones in the global `config.toml` file.

One can also use environment variables to override parameter values defined in the configuration files.<br/>
Use the format `SNOWFLAKE_<config-section>_<variable>=<value>`, where:

- `<config_section>` is the name of a section in the configuration file, with periods (`.`) replaced with underscores
  (`_`), e.g., `CLI_LOGS`.
- `<variable>` is the name of a variable defined in that section, e.g. `path`.

<details style='padding: 0 0 1rem 1rem'>
  <summary>Examples</summary>

```sh
# Override the path parameter in the [cli.logs] section in the config.toml file
SNOWFLAKE_CLI_LOGS_PATH='/Users/jondoe/snowcli_logs' snow …

# Set the password for the 'myconnection' connection
SNOWFLAKE_CONNECTIONS_MYCONNECTION_PASSWORD='SomePassword'

# Set the default connection name
SNOWFLAKE_DEFAULT_CONNECTION_NAME='myconnection'
```

</details>

## Usage

```sh
# Add connections
snow connection add
snow --config-file 'my_config.toml' connection add \
  -n 'myconnection2' --account 'myaccount2' --user 'jdoe2' --no-interactive

# List connections
snow connection list

# Test connections
snow connection test
snow --config-file='my_config.toml' connection test -c 'myconnection2' --enable-diag --diag-log-path "$HOME/report"

# Set the default connection
snow connection set-default 'myconnection2'
```

## Further readings

- [Snowflake]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Snowflake]: README.md

<!-- Files -->
<!-- Upstream -->
[Configuring Snowflake CLI]: https://docs.snowflake.com/en/developer-guide/snowflake-cli/connecting/configure-cli
[Managing Snowflake connections]: https://docs.snowflake.com/en/developer-guide/snowflake-cli/connecting/configure-connections
[snowflake cli repository]: https://sfc-repo.snowflakecomputing.com/snowflake-cli/index.html
[snowflake cli]: https://docs.snowflake.com/en/developer-guide/snowflake-cli/index

<!-- Others -->
