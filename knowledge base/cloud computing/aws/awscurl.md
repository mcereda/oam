# `awscurl`

[`curl`][curl]-like tool with AWS Signature Version 4 request signing.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
brew install 'awscurl'
docker pull 'okigan/awscurl'
pip install 'awscurl'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Credentials are inferred from the default profile if none is given.
awscurl --service 'es' 'https://search-domain.eu-west-1.es.amazonaws.com/_cluster/health?pretty'
awscurl --region 'eu-south-1' --service 'aps' -X 'POST' 'https://aps.workspace.url/api/v1/query?query=up'
awscurl --profile 'work' …
awscurl --access_key 'access-key-id' --secret_key 'secret-key' …

# Set query data out of the URL.
awscurl … --service 'aps' 'https://aps.workspace.url/api/v1/query/api/v1/query' \
  -d 'query=up' -d 'time=1652382537' -d 'stats=all'
awscurl … --service 'aps' 'https://aps.workspace.url/api/v1/query/api/v1/query_range' \
  -d 'query=sum+%28rate+%28go_gc_duration_seconds_count%5B1m%5D%29%29' \
  -d 'start=1652382537' -d 'end=1652384705' -d 'step=1000' -d 'stats=all'

# Run in containers.
docker run --rm -it -v "$HOME/.aws:/root/.aws:ro" 'okigan/awscurl' …
docker run --rm -it -e 'AWS_ACCESS_KEY_ID' -e 'AWS_SECRET_ACCESS_KEY' 'okigan/awscurl' \
  --region 'eu-south-1' --service 'aps' \
  --access_key "$AWS_ACCESS_KEY_ID" --secret_key "$AWS_SECRET_ACCESS_KEY" \
  'https://aps.workspace.url/api/v1/query/api/v1/query?query=up'
```

</details>

## Further readings

- [Amazon Web Services]
- [Codebase]

### Sources

- [Using awscurl to query Prometheus-compatible APIs]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[amazon web services]: README.md
[curl]: ../../curl.md

<!-- Upstream -->
[codebase]: https://github.com/okigan/awscurl

<!-- Others -->
[using awscurl to query prometheus-compatible apis]: https://docs.aws.amazon.com/prometheus/latest/userguide/AMP-compatible-APIs.html
