# Turbot Powerpipe

Quick 'n' easy dashboards for DevOps.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Powerpipe **requires** a database to run its queries from.<br/>
By default it uses [Steampipe]'s, but it [can be specified][selecting a database].

_Controls_ allow to draw specific conclusion (e.g. 'OK', 'Alarm') about each row in queries.<br/>
_Benchmarks_ group controls and other benchmarks into hierarchies of any depth.

Default files directory (called _installation directory_ by Powerpipe) is `$HOME/.powerpipe`.

<details>
  <summary>Installation and configuration</summary>

```sh
brew install 'turbot/tap/powerpipe'
```

```sh
# Initialize the current directory.
# Creates a 'mod.pp' file.
powerpipe mod init

# Disable telemetry.
export POWERPIPE_TELEMETRY='none'

# Configuration.
# Most can be set through switch.
# These are set to their defaults.
export \
  POWERPIPE_INSTALL_DIR="${HOME}/.powerpipe" \
  POWERPIPE_LISTEN='network' \
  POWERPIPE_MAX_PARALLEL=10 \
  POWERPIPE_MOD_LOCATION="$PWD" \
  POWERPIPE_PORT=9033 \
  POWERPIPE_UPDATE_CHECK=true
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Install mods with their dependencies.
# If none is given, install all those specified in the 'mod.pp' configuration file.
powerpipe mod install
powerpipe mod install 'github.com/turbot/steampipe-mod-aws-insights' 'github.com/turbot/steampipe-mod-aws-tags@v0.13'
powerpipe mod install --dry-run 'github.com/turbot/steampipe-mod-aws-compliance@^0.92'

# List installed mods.
powerpipe mod list

# Update mods.
powerpipe mod update 'github.com/turbot/steampipe-mod-aws-compliance'

# Uninstall mods.
powerpipe mod uninstall 'github.com/turbot/steampipe-mod-aws-compliance'

# List available queries.
powerpipe query list

# Show queries' information.
powerpipe query show 'aws_insights.query.vpc_vpcs_for_vpc_subnet'

# Run named queries.
powerpipe query run 'aws_insights.query.vpc_vpcs_for_vpc_subnet'

# List available controls.
powerpipe control list

# Execute controls.
# Only one at a time.
powerpipe control run 'aws_compliance.control.cis_v150_3_3'

# List available benchmarks.
powerpipe benchmark list

# Execute benchmarks.
powerpipe benchmark run 'aws_compliance.benchmark.cis_v300' 'aws_compliance.benchmark.gdpr'
powerpipe benchmark run … --where "severity in ('critical', 'high')" --tag 'cis_level=1' --tag 'cis=true'
powerpipe benchmark run … --output 'brief' --export 'output.csv' --export 'output.json' --export 'md' --export 'nunit3'
powerpipe benchmark run … --database 'postgres://myUser:myPassword@myDbFqdn:9193/steampipe'

# Run *all* benchmarks in mods.
# This will *not* run benchmarks in the mods' dependencies.
powerpipe benchmark run all

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
