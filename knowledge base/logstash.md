# Logstash

Server-side data processing pipeline that ingests data, transforms it, and then sends the results to any collector.

Part of the Elastic Stack along with Beats, [ElasticSearch] and [Kibana].

1. [TL;DR](#tldr)
1. [Troubleshooting](#troubleshooting)
   1. [Check a pipeline is processing data](#check-a-pipeline-is-processing-data)
   1. [Log pipeline data to stdout](#log-pipeline-data-to-stdout)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
dnf install 'logstash'
docker pull 'logstash:7.17.27'
yum install 'logstash'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Get a shell in the docker image.
docker run --rm -ti --name 'logstash' --entrypoint 'bash' 'logstash:7.17.27'

# Validate configuration files.
logstash -tf 'config.conf'
logstash --config.test_and_exit --path.config 'config.conf' --api.enabled='false'
# If given a directory, will load and check all files in it.
logstash --config.test_and_exit --path.config 'configDir' --log.level='debug'
docker run --rm -ti -v "$PWD:/usr/share/logstash/custom" 'docker.io/library/logstash:7.17.27' -tf 'custom'

# Automatically reload configuration files on change.
# Default interval is '3s'.
logstash … --config.reload.automatic
logstash … --config.reload.automatic --config.reload.interval '5s'

# Force configuration files reload and restart the pipelines.
kill -SIGHUP '14175'


# Install plugins.
logstash-plugin install 'logstash-output-loki'

# List installed plugins.
logstash-plugin list
logstash-plugin list --verbose
logstash-plugin list '*namefragment*'
logstash-plugin list --group 'output'


# Get Logstash's status.
curl -fsS 'localhost:9600/_health_report?pretty'

# Get pipelines' statistics.
curl -fsS 'localhost:9600/_node/stats/pipelines?pretty'
curl -fsS 'localhost:9600/_node/stats/pipelines/somePipeline?pretty'
```

```rb
input {
  file {
    path => "/var/log/logstash/logstash-plain.log"
  }
  syslog {
    port => 9292
    codec => "json"
  }
  tcp {
    port => 9191
    codec => "json"
  }
}

filter {
  grok {
    match => { "message" => "\[%{TIMESTAMP_ISO8601:timestamp}\]\[%{LOGLEVEL:loglevel}\] .+" }
  }
  json {
    skip_on_invalid_json => true
    source => "message"
    add_tag => ["json_body"]
  }
  mutate {
    add_field => {
      "cluster" => "eu-west-1"
      "job" => "logstash"
    }
    replace => { "type" => "stream"}
    remove_field => [ "src" ]
  }

  if [loglevel] != "ERROR" and [loglevel] != "WARN" {
    drop { }
  }
}

output {
  loki {
    url => "http://loki.example.org:3100/loki/api/v1/push"
  }
  opensearch {
    hosts => [ "https://os.example.org:443" ]
    auth_type => {
      type => 'aws_iam'
      region => 'eu-west-1'
    }
    index => "something-%{+YYYY.MM.dd}"
    action => "create"
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

## Troubleshooting

### Check a pipeline is processing data

<details>
  <summary>Steps in order of likeliness</summary>

1. Check the Logstash process is running correctly

   ```sh
   systemctl status 'logstash.service'
   journalctl -xefu 'logstash.service'

   docker ps
   docker logs 'logstash'
   ```

1. Check the Logstash process is getting and/or sending data:

   ```sh
   tcpdump 'dst port 8765 or dst opensearch.example.org'
   ```

1. Check the pipeline's statistics are changing:

   ```sh
   curl -fsS 'localhost:9600/_node/stats/pipelines/somePipeline' \
   | jq '.pipelines."somePipeline"|{"events":.events,"queue":.queue}' -
   ```

   ```json
   {
     "events": {
       "in": 20169,
       "out": 20169,
       "queue_push_duration_in_millis": 11,
       "duration_in_millis": 257276,
       "filtered": 20169
     },
     "queue": {
       "type": "memory",
       "events_count": 0,
       "queue_size_in_bytes": 0,
       "max_queue_size_in_bytes": 0
     }
   }
   ```

1. Check the pipeline's input and output plugin's statistics are changing:

   ```sh
   curl -fsS 'localhost:9600/_node/stats/pipelines/somePipeline' \
   | jq '.pipelines."somePipeline".plugins|{"in":.inputs,"out":.outputs[]|select(.name=="opensearch")}' -
   ```

1. [Log the pipeline's data to stdout][log pipeline data to stdout] to check data is parsed correctly.

</details>

### Log pipeline data to stdout

Leverage the `stdout` output plugin in any pipeline's configuration file:

```rb
output {
  stdout {
    codec => rubydebug {
      metadata => true   # also print metadata in console
    }
  }
}
```

## Further readings

- [Website]
- [Codebase]
- [Documentation]
- [Beats], [ElasticSearch] and [Kibana]: the rest of the Elastic stack

### Sources

- [How to debug your Logstash configuration file]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[log pipeline data to stdout]: #log-pipeline-data-to-stdout

<!-- Knowledge base -->
[beats]: beats.md
[elasticsearch]: elasticsearch.md
[kibana]: kibana.md

<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/elastic/logstash
[documentation]: https://www.elastic.co/guide/en/logstash/current/
[website]: https://www.elastic.co/logstash

<!-- Others -->
[how to debug your logstash configuration file]: https://logz.io/blog/debug-logstash/
