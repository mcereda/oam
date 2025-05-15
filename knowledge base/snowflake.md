# Snowflake

> TODO

Intro

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Snowflake CLI](#snowflake-cli)
1. [RoleOut](#roleout)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

  <details style='padding: 0 0 0 1rem'>
    <summary>Linux (DEB)</summary>

```sh
# Install Snowflake's CLI.
# Get it from the [Snowflake CLI repository].
curl --continue-at '-' --location --fail --show-error --remote-name \
  --url 'https://sfc-repo.snowflakecomputing.com/snowflake-cli/linux_aarch64/3.7.2/snowflake-cli-3.7.2.aarch64.deb' \
&& sudo dpkg -i 'snowflake-cli-3.7.2.aarch64.deb'
```

  </details>

  <details style='padding: 0 0 0 1rem'>
    <summary>Linux (RPM)</summary>

```sh
# Install Snowflake's CLI.
# Get it from the [Snowflake CLI repository].
curl --continue-at '-' --location --fail --show-error --remote-name \
  --url 'https://sfc-repo.snowflakecomputing.com/snowflake-cli/linux_aarch64/3.7.2/snowflake-cli-3.7.2.aarch64.rpm' \
&& sudo rpm -i 'snowflake-cli-3.7.2.rpm'
```

  </details>

  <details style='padding: 0 0 0 1rem'>
    <summary>Mac OS X</summary>

```sh
# Install Snowflake's CLI.
brew install 'snowflake-cli'

# Install RoleOut's UI and CLI.
curl -C '-' -LfSO --url 'https://github.com/Snowflake-Labs/roleout/releases/download/v2.0.1/Roleout-2.0.1-arm64.dmg' \
&& sudo installer -pkg 'Roleout-2.0.1-arm64.dmg' -target '/' \
&& curl -C '-' -LfS --url 'https://github.com/Snowflake-Labs/roleout/releases/download/v2.0.1/roleout-cli-macos' \
     --output "$HOME/bin/roleout-cli" \
&& chmod 'u+x' "$HOME/bin/roleout-cli" \
&& xattr -d 'com.apple.quarantine' "$HOME/bin/roleout-cli"
```

  </details>

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

```sql
SHOW USERS;
SHOW USERS LIKE '%john%';

CREATE USER alice;
CREATE USER IF NOT EXISTS bob;
CREATE OR REPLACE USER claude
  PASSWORD='somePassword' DISPLAY_NAME='Claude' EMAIL='claude@example.org'
  LOGIN_NAME='CLAUDE@EXAMPLE.ORG' MUST_CHANGE_PASSWORD=TRUE;

GRANT ROLE someRole TO USER diane;
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Snowflake CLI

Refer [Snowflake CLI].

Meant to replace the SnowSQL tool.

Download from the [Snowflake CLI repository].

```sh
# Linux (DEB).
curl --continue-at '-' --location --fail --show-error --remote-name \
  --url 'https://sfc-repo.snowflakecomputing.com/snowflake-cli/linux_aarch64/3.7.2/snowflake-cli-3.7.2.aarch64.deb' \
&& sudo dpkg -i 'snowflake-cli-3.7.2.aarch64.deb'

# Linux (RPM).
curl --continue-at '-' --location --fail --show-error --remote-name \
  --url 'https://sfc-repo.snowflakecomputing.com/snowflake-cli/linux_aarch64/3.7.2/snowflake-cli-3.7.2.aarch64.rpm' \
&& sudo rpm -i 'snowflake-cli-3.7.2.rpm'

# Mac OS X.
# Via Homebrew.
brew install 'snowflake-cli'
# Via the [Snowflake CLI repository].
curl --continue-at '-' --location --fail --show-error --remote-name \
  --url 'https://sfc-repo.snowflakecomputing.com/snowflake-cli/darwin_arm64/3.7.2/snowflake-cli-3.7.2-darwin-arm64.pkg' \
&& sudo installer -pkg 'snowflake-cli-3.7.2-darwin-arm64.pkg' -target '/' \
&& ln -swiv '/Applications/SnowflakeCLI.app/Contents/MacOS/snow' "$HOME/bin/snow"
```

## RoleOut

```sh
# Mac OS X.
curl -C '-' -LfSO --url 'https://github.com/Snowflake-Labs/roleout/releases/download/v2.0.1/Roleout-2.0.1-arm64.dmg' \
&& sudo installer -pkg 'Roleout-2.0.1-arm64.dmg' -target '/' \
&& curl -C '-' -LfS --url 'https://github.com/Snowflake-Labs/roleout/releases/download/v2.0.1/roleout-cli-macos' \
     --output "$HOME/bin/roleout-cli" \
&& chmod 'u+x' "$HOME/bin/roleout-cli" \
&& xattr -d 'com.apple.quarantine' "$HOME/bin/roleout-cli"
```

## Further readings

- [Website]

### Sources

- [Documentation]
- [Snowflake CLI]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[documentation]: https://docs.snowflake.com/en/
[website]: https://www.snowflake.com/en/
[snowflake cli]: https://docs.snowflake.com/en/developer-guide/snowflake-cli/index
[snowflake cli repository]: https://sfc-repo.snowflakecomputing.com/snowflake-cli/index.html

<!-- Others -->
