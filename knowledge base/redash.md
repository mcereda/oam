# Redash

> TODO

Intro

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [API](#api)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<!-- Uncomment if used
<details>
  <summary>Setup</summary>

```sh
```

</details>
-->

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

## API

Refer [API].

Prefer acting on them via [getredash/redash-toolbelt].

<details style='padding: 0 0 1rem 1rem'>
  <summary>Data sources</summary>

```plaintext
GET /api/data_sources
GET /api/data_sources/42

POST /api/data_sources
{
  "name": "some data source",
  "type": "pg",
  "options": {
    "host": "db.fqdn",
    "port": 5432,
    "dbname": "postgres",
    "user": "postgres",
    "password": "someStr0ngPa$$w0rd",
  }
}
```

```sh
curl --request 'GET' --url 'https://redash.example.org/api/data_sources' --header 'Authorization: Key AA…99'

curl --request 'POST' --url 'https://redash.example.org/api/data_sources' --header 'Authorization: Key AA…99' \
  --data '{
    "name": "some data source",
    "type": "pg",
    "options": {
      "host": "db.fqdn",
      "port": 5432,
      "dbname": "postgres",
      "user": "postgres",
      "password": "someStr0ngPa$$w0rd",
    }
  }'
```

```py
from redash_toolbelt import Redash
from requests import Response

data_source_name: str = 'some data source'
data_source_type: str = 'pg'
data_source_options: object = {
    host = 'db.fqdn',
    port = 5432,  # must be int
    dbname = 'postgres',
    user = 'postgres',
    password = 'someStr0ngPa$$w0rd',
}

response: Response = redash.create_data_source(data_source_name, data_source_type, data_source_options)
```

</details>

## Further readings

- [Website]
- [Codebase]

### Sources

- [Documentation]
- [API]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[API]: https://redash.io/help/user-guide/integrations-and-api/api/
[Codebase]: https://github.com/getredash/redash
[Documentation]: https://redash.io/help/
[Website]: https://redash.io/
[getredash/redash-toolbelt]: https://github.com/getredash/redash-toolbelt

<!-- Others -->
