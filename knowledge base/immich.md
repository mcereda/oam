# Immich

Self-hosted photo and video management solution.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
curl -O 'https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml' \
&& curl -o '.env' 'https://github.com/immich-app/immich/releases/latest/download/example.env' \
&& curl -O 'https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml' \
&& curl -O 'https://github.com/immich-app/immich/releases/latest/download/hwaccel.ml.yml' \
&& docker compose up -d \
&& xdg-open 'http://localhost:2283'
```

The composition uses `.env` for configuration.<br/>
Refer the [Environment Variables] documentation page for the available environment variables.
</details>

<details>
  <summary>Usage</summary>

```sh
# Backup the DB.
docker exec -t 'immich_postgres' pg_dumpall --clean --if-exists --username='postgres' \
| gzip > '/path/to/backup/dump.sql.gz'

# Restore the DB.
# The procedure deletes *all* data to start from scratch.
source '.env' \
&& docker compose down -v \
&& rm -rf "$DB_DATA_LOCATION" \
&& docker compose create \
&& docker start 'immich_postgres' && sleep 10 \
&& gunzip < '/path/to/backup/dump.sql.gz' \
  | sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', true);/g" \
  | docker exec -i 'immich_postgres' psql --username='postgres' \
&& docker compose up -d
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

- [Website]
- [Main repository]
- [Environment Variables]

### Sources

- [Backup and Restore]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[backup and restore]: https://immich.app/docs/administration/backup-and-restore
[environment variables]: https://immich.app/docs/install/environment-variables
[main repository]: https://github.com/immich-app/immich
[website]: https://immich.app/

<!-- Others -->
