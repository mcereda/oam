# Evidently

AI observability tool written in [Python].

1. [TL;DR](#tldr)
1. [ML monitoring dashboard](#ml-monitoring-dashboard)
   1. [Remote snapshot storage](#remote-snapshot-storage)
1. [Collector](#collector)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
pip install 'evidently'
pip install 'evidently[llm]' 's3fs' 'tracely'
```

</details>

<details>
  <summary>Usage</summary>

```sh
evidently ui
evidently ui … --host='0.0.0.0' --port='8080'
FSSPEC_S3_KEY='AKIA2HKHF74L0123ABCD' FSSPEC_S3_SECRET='jlc/m1sO…' evidently ui … --workspace='s3://bucket/prefix'

evidently collector
```

</details>

## ML monitoring dashboard

Visualizes ML system performance over time and allows for issues detection.

Available as cloud service or self-hosted.<br/>
Evidently Cloud offers extra features (e.g. user authentication and roles, built-in alerting, no-code interface).

### Remote snapshot storage

One can store snapshots in a remote data store such as S3 buckets.<br/>
The Monitoring UI service will interface with it to read the snapshots' data.

Evidently connects to data stores using [`fsspec`][fsspec].<br/>
It allows accessing data on remote file systems via standard Python interfaces
([built-in implementations][fsspec built-in implementations], [other implementations][fsspec other implementations]).

```sh
pip install 'evidently[llm]' 's3fs'
evidently ui --host='0.0.0.0' --port='8000' --workspace='s3://bucket/prefix'
```

## Collector

```sh
evidently collector
```

## Further readings

- [Website]
- [Main repository]
- [Docker image]
- [Python]
- [`fsspec`][fsspec]
- [ML observability course]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[python]: python.md

<!-- Files -->
<!-- Upstream -->
[docker image]: https://hub.docker.com/r/evidently/evidently-service
[documentation]: https://docs.evidentlyai.com/
[main repository]: https://github.com/evidentlyai/evidently
[ml observability course]: https://learn.evidentlyai.com/
[website]: https://www.evidentlyai.com/

<!-- Others -->
[fsspec built-in implementations]: https://filesystem-spec.readthedocs.io/en/latest/api.html#built-in-implementations
[fsspec other implementations]: https://filesystem-spec.readthedocs.io/en/latest/api.html#other-known-implementations
[fsspec]: https://filesystem-spec.readthedocs.io/en/latest/
