# Turbot Powerpipe

Quick 'n' easy dashboards for DevOps.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Powerpipe **requires** a database to run its queries from.<br/>
By default it uses [Steampipe]'s, but it [can be specified][selecting a database].

<details>
  <summary>Installation and configuration</summary>

```sh
brew install 'turbot/tap/powerpipe'
```

```sh
powerpipe mod init
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Install mods.
# If none given, install all those specified in 'mod.pp' with their dependencies.
powerpipe mod install
powerpipe mod install 'github.com/turbot/steampipe-mod-aws-insights'
powerpipe mod install --dry-run 'github.com/turbot/steampipe-mod-aws-compliance@v0.93.0'
powerpipe mod install github.com/turbot/steampipe-mod-aws-compliance@'^1'

# Start the dashboard.
# Wait for server initialization before connecting.
powerpipe server
powerpipe server --listen 'network' --port '8080'
```

</details>

<!-- Uncomment if needed
<details>
  <summary>Real world use cases</summary>
</details>
-->

## Further readings

- [Website]
- [Github]
- [Flowpipe]
- [Steampipe]

### Sources

- [Turbot pipes]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[flowpipe]: flowpipe.md
[steampipe]: steampipe.md
[turbot pipes]: README.md

<!-- Files -->
<!-- Upstream -->
[website]: https://powerpipe.io/
[github]: https://github.com/turbot/powerpipe
[selecting a database]: https://powerpipe.io/docs/run#selecting-a-database

<!-- Others -->
