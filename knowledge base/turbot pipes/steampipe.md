# Turbot Steampipe

Dynamically query APIs, code and more with SQL.

1. [TL;DR](#tldr)
1. [Export CLIs](#export-clis)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Default files directory (called _installation directory_ by Steampipe) is `$HOME/.steampipe`.

<details>
  <summary>Installation and configuration</summary>

```sh
brew install 'turbot/tap/steampipe'

steampipe completion 'fish' | source
steampipe completion 'fish' > "$HOME/.config/fish/completions/steampipe.fish"

# Disable telemetry.
export STEAMPIPE_TELEMETRY='none'

# Most used configuration settings.
# Most can be set through switch.
# These are set to their defaults.
export \
  STEAMPIPE_INSTALL_DIR="${HOME}/.steampipe" \
  STEAMPIPE_LOG_LEVEL="WARN" \
  STEAMPIPE_MAX_PARALLEL=10 \
  STEAMPIPE_MOD_LOCATION="$PWD" \
  STEAMPIPE_UPDATE_CHECK=true
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Install plugins.
steampipe plugin install 'steampipe' 'aws@^0.130' 'theapsgroup/gitlab@v0.6.0'

# List installed plugins.
steampipe plugin list

# Update plugins.
steampipe plugin update --all
steampipe plugin update 'steampipe' 'aws'

# Uninstall plugins.
steampipe plugin uninstall 'steampipe' 'theapsgroup/gitlab@0.6.0' 'hub.steampipe.io/plugins/turbot/aws@^0'

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

# Execution of benchmarks and controls has been deprecated in favour of Powerpipe.
#steampipe check 'benchmark.cis_v130'
#steampipe check 'control.cis_v130_1_4' 'control.cis_v130_2_1_1'
#steampipe check 'all'
#steampipe check … --tag 'cis_level=1' --tag 'cis=true' --search-path-prefix 'aws_connection_2'
#steampipe check … --where "severity in ('critical', 'high')" --dry-run
#steampipe check … --theme 'light' --output 'brief' --export 'output.csv' --export 'output.json' --export 'md'
#steampipe check … --theme 'plain' --progress false
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

Dashboards and Mods have been deprecated in favour of [Powerpipe]. Use it instead.

</details>

## Export CLIs

Every Steampipe plugin is distributed as a distinct Steampipe Export CLI.<br/>
It is available for download in the Releases page for the corresponding plugin's repository.

Download, extract, and install the file.<br/>
An install script is available for ease of use:

```sh
$ /bin/sh -c "$(curl -fsSL https://steampipe.io/install/export.sh)"
Enter the plugin name: aws
Enter the version (latest):
Enter location (/usr/local/bin):
Created temporary directory at /var/folders/t4/1lm46wt12sv7yq1gp1swn3jr0000gn/T/tmp.RpZLlzs2.

Downloading steampipe_export_aws.darwin_arm64.tar.gz...
######################################################################### 100.0%
Deflating downloaded archive
x steampipe_export_aws
Installing
Applying necessary permissions
Removing downloaded archive
steampipe_export_aws was installed successfully to /usr/local/bin
```

The output can be in CSV (default), JSON or [JSONL](https://jsonlines.org/).

```sh
$ steampipe_export_aws 'aws_account' --output 'json'
2024/05/24 12:03:53 [INFO] Memoize getBaseClientForAccountUncached
…
2024/05/24 12:03:53 [INFO] Memoize 0x109fed0c0 listRegionsForServiceUncached
[{
    "_ctx": "{\"connection_name\":\"aws\",\"steampipe\":{\"sdk_version\":\"5.10.0\"}}",
    "account_aliases": "[\"exampleOrg\"]",
    "account_id": "012345678901",
    "akas": "[\"arn:aws:::012345678901\"]",
    "arn": "arn:aws:::012345678901",
    "organization_arn": "arn:aws:organizations::012345678901:organization/o-p42ybyw9ml",
    "organization_available_policy_types": "[{\"Status\":\"ENABLED\",\"Type\":\"SERVICE_CONTROL_POLICY\"}]",
    "organization_feature_set": "ALL",
    "organization_id": "o-p42ybyw9ml",
    "organization_master_account_arn": "arn:aws:organizations::012345678901:account/o-p42ybyw9ml/012345678901",
    "organization_master_account_email": "user@example.org",
    "organization_master_account_id": "012345678901",
    "partition": "aws",
    "region": "global",
    "sp_connection_name": "aws",
    "sp_ctx": "{\"connection_name\":\"aws\",\"steampipe\":{\"sdk_version\":\"5.10.0\"}}",
    "title": "exampleOrg"
}]
```

## Further readings

- [Website]
- [Github]
- [Steampipe unbundled]
- [Flowpipe]
- [Powerpipe]
- [Steampipe and Postgres]
- [Connecting Steampipe with Google BigQuery]

### Sources

- [Turbot pipes]
- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[flowpipe]: flowpipe.md
[powerpipe]: powerpipe.md
[turbot pipes]: README.md

<!-- Upstream -->
[documentation]: https://steampipe.io/docs
[github]: https://github.com/turbot/steampipe
[steampipe unbundled]: https://steampipe.io/blog/steampipe-unbundled
[website]: https://steampipe.io/

<!-- Others -->
[connecting steampipe with google bigquery]: https://briansuk.medium.com/connecting-steampipe-with-google-bigquery-ae37f258090f
[steampipe and postgres]: https://www.reddit.com/r/aws/comments/uh8w9k/steampipe_and_postgres/
