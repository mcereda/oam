# awscurl

[`curl`][curl]-like tool with AWS Signature Version 4 request signing.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Installation</summary>

```sh
brew install 'awscurl'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Credentials are inferred from the default profile if none is given.
awscurl -X 'POST' --region 'eu-south-1' --service 'aps' \
  'https://aps.workspace.url/api/v1/query?query=up'
awscurl … --profile 'work'
awscurl … --access_key 'access-key-id' --secret_key 'secret-key'

# Set query data out of the URL.
awscurl … 'https://aps.workspace.url/api/v1/query/api/v1/query' \
  -d 'query=up' -d 'time=1652382537' -d 'stats=all'
awscurl … 'https://aps.workspace.url/api/v1/query/api/v1/query_range' \
  -d 'query=sum+%28rate+%28go_gc_duration_seconds_count%5B1m%5D%29%29' \
  -d 'start=1652382537' -d 'end=1652384705' -d 'step=1000' -d 'stats=all'

# Run in containers.
docker run --rm -it 'okigan/awscurl' \
  --region 'eu-south-1' --service 'aps' \
  --access_key "$AWS_ACCESS_KEY_ID" --secret_key "$AWS_SECRET_ACCESS_KEY" \
  'https://aps.workspace.url/api/v1/query/api/v1/query?query=up'
```

</details>

## Further readings

- [Github]

### Sources

- [Using awscurl to query Prometheus-compatible APIs]

<!--
  References
  -->

<!-- Knowledge base -->
[curl]: ../../curl.md

<!-- Upstream -->
[github]: https://github.com/okigan/awscurl

<!-- Others -->
[using awscurl to query prometheus-compatible apis]: https://docs.aws.amazon.com/prometheus/latest/userguide/AMP-compatible-APIs.html
