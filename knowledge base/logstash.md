# Logstash

Server-side data processing pipeline that ingests data, transforms it, and then sends the results to any collector.

Part of the Elastic Stack along with Beats, [ElasticSearch] and [Kibana].

1. [TL;DR](#tldr)
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

<details>
  <summary>Usage</summary>

```sh
# Validate configuration files.
logstash -tf 'config.conf'
logstash --config.test_and_exit --path.config 'config.conf'


# Install plugins.
logstash-plugin install 'logstash-output-loki'

# List installed plugins.
logstash-plugin list
logstash-plugin list --verbose
logstash-plugin list '*namefragment*'
logstash-plugin list --group 'output'
```

```rb
input { … }

filter {
  mutate {
    add_field => {
      "cluster" => "us-central-1"
      "job" => "logstash"
    }
    replace => { "type" => "stream"}
    remove_field => [ "src" ]
  }
}

output {
  loki {
    url => "http://loki.example.org:3100/loki/api/v1/push"
  }
}
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
- [Codebase]
- [Beats], [ElasticSearch] and [Kibana]: the rest of the Elastic stack

### Sources

- [How to debug your Logstash configuration file]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[beats]: beats.md
[elasticsearch]: elasticsearch.md
[kibana]: kibana.md

<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/elastic/logstash
[website]: https://website/

<!-- Others -->
[how to debug your logstash configuration file]: https://logz.io/blog/debug-logstash/
