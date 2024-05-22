# Turbot Steampipe

Dynamically query APIs, code and more with SQL.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Default config directory is `$HOME/.steampipe`.

<details>
  <summary>Installation and configuration</summary>

```sh
brew install 'turbot/tap/steampipe'

steampipe completion fish | source
steampipe completion fish > "$HOME/.config/fish/completions/steampipe.fish"
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Install plugins.
steampipe plugin install 'steampipe'
steampipe plugin install 'aws'

# Start the service.
steampipe service start
steampipe service start --database-port '9194'
steampipe service start --database-listen 'local' --database-password 'MyCustomPassword'

# Get the service's status.
steampipe service status
steampipe service status --all

# View the database's password.
steampipe service status --show-password

# Restart the service.
steampipe service restart

# Stop the service.
steampipe service stop
steampipe service stop --force

# List available queries.
# Requires the 'mod' folder to exist.
steampipe query list

# Start the interactive query console.
steampipe query

# Execute batch queries.
steampipe query 'query'
steampipe query 'query' --output 'json'
steampipe query 'query' --output 'csv' --separator '|'

# Executes benchmarks and controls.
steampipe check 'benchmark.cis_v130'
steampipe check 'control.cis_v130_1_4' 'control.cis_v130_2_1_1'
steampipe check 'all'
steampipe check … --tag 'cis_level=1' --tag 'cis=true' --search-path-prefix 'aws_connection_2'
steampipe check … --where "severity in ('critical', 'high')" --dry-run
steampipe check … --theme 'light' --output 'brief' --export 'output.csv' --export 'output.json' --export 'md'
steampipe check … --theme 'plain' --progress false
```

</details>

<details>
  <summary>Real world use cases</summary>

```sql
-- Find all the roles that have AWS-managed policies attached
select
  r.name,
  policy_arn,
  p.is_aws_managed
from
  aws_iam_role as r,
  jsonb_array_elements_text(attached_policy_arns) as policy_arn,
  aws_iam_policy as p
where
  p.arn = policy_arn
  and p.is_aws_managed;
```

Dashboards have been deprecated from Steampipe. Use [Powerpipe] instead.

</details>

## Further readings

- [Website]
- [Github]
- [Steampipe unbundled]
- [Flowpipe]
- [Powerpipe]

### Sources

- [Turbot pipes]
- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[flowpipe]: flowpipe.md
[powerpipe]: powerpipe.md
[turbot pipes]: README.md

<!-- Files -->
<!-- Upstream -->
[documentation]: https://steampipe.io/docs
[github]: https://github.com/turbot/steampipe
[steampipe unbundled]: https://steampipe.io/blog/steampipe-unbundled
[website]: https://steampipe.io/

<!-- Others -->
