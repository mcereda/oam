# Snowflake

> TODO

Intro

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Snowflake CLI](#snowflake-cli)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Install Snowflake CLI.
# Get it from the [Snowflake CLI repository].
curl -fsSLO 'https://sfc-repo.snowflakecomputing.com/snowflake-cli/linux_aarch64/3.4.1/snowflake-cli-3.4.1.aarch64.deb' \
&& dpkg -i 'snowflake-cli-3.4.1.aarch64.deb'
curl -fsSLO 'https://sfc-repo.snowflakecomputing.com/snowflake-cli/darwin_arm64/3.4.1/snowflake-cli-3.4.1-darwin-arm64.pkg' \
&& sudo installer -pkg 'snowflake-cli-3.4.1-darwin-arm64.pkg' -target '/'
curl -fsSLO 'https://sfc-repo.snowflakecomputing.com/snowflake-cli/linux_aarch64/3.4.1/snowflake-cli-3.4.1.aarch64.rpm' \
&& rpm -i 'snowflake-cli-3.4.1.rpm'

# Check it works.
snow --help
```

</details>

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

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
curl -fsSLO 'https://sfc-repo.snowflakecomputing.com/snowflake-cli/darwin_arm64/3.4.1/snowflake-cli-3.4.1-darwin-arm64.pkg' \
&& sudo installer -pkg 'snowflake-cli-3.4.1-darwin-arm64.pkg' -target '/'
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
