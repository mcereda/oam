# Airbyte

Open-source ELT (Extract-Load-Transform) platform meant to move data between sources and destinations.

1. [TL;DR](#tldr)
1. [REST API](#rest-api)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details style='padding: 0 0 1rem 0'>
  <summary>Usage</summary>

```sh
curl 'https://airbyte.example.org/api/v1/workspaces/list' \
  -u 'someUsername:somePassword' \
  -X 'POST' -H 'Content-Type: application/json' -d '{}' \
  …
curl -H "Authorization: Basic $(printf '%s:%s' 'someUsername' 'somePassword' | base64)" …
```

</details>

## REST API

Self-hosted instances typically use Basic authentication.

All endpoints answer to `POST` request, which requires them to set `Content-Type: application/json`.

Most _list_ and _get_ endpoints require the requests' `POST` body to include a `workspaceId`. That ID is the canonical
way to scope an instance.

<details style='padding: 0 0 1rem 0'>
  <summary>Common endpoints</summary>

List workspaces:

```plaintext
POST /api/v1/workspaces/list
{}
```

List connections:

```plaintext
POST /api/v1/connections/list
Content-Type: application/json
{
  "workspaceId": "<workspace-id>"
}
```

List sources:

```plaintext
POST /api/v1/sources/list
Content-Type: application/json
{
  "workspaceId": "<workspace-id>"
}
```

Get a specific source configuration (including `connectionConfiguration`):

```plaintext
POST /api/v1/sources/get
Content-Type: application/json
{
  "sourceId": "<uuid>"
}
```

</details>

> [!note]
> The replication slot's name and the publication's name are **not** top-level fields. They live nested in a source
> configuration under `connectionConfiguration.replication_method`.
>
> <details style='padding: 0 0 1rem 1rem'>
>
> ```json
> {
>   "sourceId": "…",
>   "connectionConfiguration": {
>     "host": "192.168.25.50",
>     "port": 5432,
>     "database": "asterisk",
>     "username": "asterisk",
>     "replication_method": {
>       "method": "CDC",
>       "replication_slot": "asterisk_replication_slot",
>       "publication": "asterisk_publication",
>       "plugin": "pgoutput"
>     }
>   }
> }
> ```
>
> </details>
>
> The top-level `connectionConfiguration` response **looks** like a flat config, but `replication_method` is its own
> nested object. Querying `.replication_slot` at the top level returns `null`; one must go through
> `.replication_method.replication_slot`.

## Further readings

- [PostgreSQL]

### Sources

- [Airbyte API reference]
- [Airbyte PostgreSQL source documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[PostgreSQL]: postgresql/README.md

<!-- Upstream -->
[Airbyte API reference]: https://reference.airbyte.com/reference/
[Airbyte PostgreSQL source documentation]: https://docs.airbyte.com/integrations/sources/postgres
