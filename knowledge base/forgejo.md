# Forgejo

Community-driven code forge platform similar to GitHub.<br/>
Forked from [Gitea] after the for-profit company Gitea Ltd took control of it.

1. [TL;DR](#tldr)
1. [Setup](#setup)
   1. [Automate backups](#automate-backups)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
apk add 'forgejo' 'forgejo-openrc'
docker pull 'codeberg.org/forgejo/forgejo'  # or 'data.forgejo.org/forgejo/forgejo'

rc-update add 'forgejo' && rc-service 'forgejo' start
```

The configuration uses the INI format.<br/>
When installing from a distribution, the configuration file will _typically_ be placed at `/etc/forgejo/app.ini`.<br/>
When using the container image, the configuration file is automatically created if it does not already exist.<br/>
Refer the [configuration cheat sheet] and the [configuration file defaults].

Values containing `#` or `;` must be quoted using `` ` `` or `"""`.

> [!important]
> Forgejo requires a **full** restart for configuration changes to take effect.

Configuration values can be _**added**_ or _**overridden**_ by setting environment variables that follow the
`FORGEJO__[SECTION]__[KEY]` format.<br/>
The `DEFAULT` section of the configuration should be an empty string.

  <details style='padding: 0 0 1rem 1rem'>

Setting environment variables as follows:

```sh
FORGEJO____APP_NAME=Frogejo 🐸
FORGEJO__repository__ENABLE_PUSH_CREATE_USER=true
```

Has the same result as adding the following to the `app.ini` configuration file:

```ini
APP_NAME=Frogejo 🐸

[repository]
ENABLE_PUSH_CREATE_USER = true
```

  </details>

Existing configuration values must be _**removed**_ by editing the configuration file.

> [!important]
> Using SELinux environments could trigger issues with containers.<br/>
> Check the audit logs in this case.

</details>

<details>
  <summary>Usage</summary>

```sh
# Get help.
forgejo help

# Check the installation.
forgejo doctor check --all --log-file '/tmp/doctor.log'

# Flush queues.
forgejo manager flush-queues

# Gracefully restart.
forgejo manager restart

# Gracefully shut down.
forgejo manager shutdown

# Backup everything into a single archive.
# Only do this when everything is on a single file system and the instance is not busy.
# Does contain a copy of the db, though open bugs may introduce problems when re-injecting the SQL dump in a new one.
forgejo dump
forgejo dump --type 'tar.gz' --file '/path/to/dump.tar.gz' --quiet

# Verify a dump file.
unzip -t '/path/to/dump.zip'
tar -tzf '/path/to/dump.tar.gz' > /dev/null

# Backup the db.
cp -a '/path/to/forgejo/workdir/db/forgejo.db' 'path/to/db/backup.db'  # only sqlite
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

<details>
  <summary>Alpine Linux</summary>

```sh
apk add 'forgejo' 'forgejo-openrc'  # add --no-cache if cache is not needed
rc-update add 'forgejo'
rc-service 'forgejo' start
```

</details>

### Automate backups

```sh
su - forgejo -c 'mkdir -m "2750" -pv "/var/lib/forgejo/backups"'
cat <<'DUMP_SCRIPT' > '/var/lib/forgejo/backups/dump.sh'
#!/bin/sh

set -e -o pipefail
: "${DATE:=$(date +%FT%H-%M-%S)}"
: "${WORKDIR:=/var/lib/forgejo}"

# dump instance and db
DUMP_FILE="${WORKDIR}/backups/dump_${DATE}.tar.gz"
echo "Dumping to '$DUMP_FILE'..."
forgejo dump --type 'tar.gz' --file "$DUMP_FILE" && echo -e "Dump succeeded\n"
echo "Copying DB..."
cp -av "${WORKDIR}/db/forgejo.db" "${WORKDIR}/backups/db_${DATE}.db" && echo -e "DB copy succeeded\n"

# verify dumps
echo "Verifying dump file '$DUMP_FILE'..."
tar -tzf "$DUMP_FILE" | tail -n '5' && echo -e "Dump file is a valid archive\n"

# retain only the last 5 archives to keep storage space in check
echo "Rotating files..."
find "${WORKDIR}/backups" -type 'f' -name "dump_*" | head -n '-5' | xargs -r rm -v && echo -e "Dumps rotated\n"
find "${WORKDIR}/backups" -type 'f' -name "db_*"   | head -n '-5' | xargs -r rm -v && echo "DB copies rotated"
DUMP_SCRIPT

chown 'forgejo:' '/var/lib/forgejo/backups/dump.sh'
chmod '2750' '/var/lib/forgejo/backups/dump.sh'
echo '43  0  *  *  *  /var/lib/forgejo/backups/dump.sh > /var/lib/forgejo/backups/dump_$(date +%FT%H-%M-%S).log 2>&1' | crontab -u 'forgejo' -
```

## Further readings

- [Website]
- [Codebase]
- [News]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Gitea]: gitea.md

<!-- Files -->
<!-- Upstream -->
[Codebase]: https://codeberg.org/forgejo/forgejo
[Configuration cheat sheet]: https://forgejo.org/docs/latest/admin/config-cheat-sheet/
[Configuration file defaults]: https://codeberg.org/forgejo/forgejo/src/branch/forgejo/custom/conf/app.example.ini
[Documentation]: https://forgejo.org/docs/latest/
[News]: https://forgejo.org/news/
[Website]: https://forgejo.org/

<!-- Others -->
