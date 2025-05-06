# Logstash

Server-side data processing pipeline that ingests data, transforms it, and then sends the results to any collector.

Part of the Elastic Stack along with Beats, [ElasticSearch] and [Kibana].

1. [TL;DR](#tldr)
1. [Create plugins](#create-plugins)
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
# If given a directory, will load and check all files in it *as if they were a single pipeline*.
logstash --config.test_and_exit --path.config 'configDir' --log.level='debug'
docker run --rm -ti -v "$PWD:/usr/share/logstash/custom-dir" 'docker.io/library/logstash:7.17.27' -tf 'custom-dir'

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

## Create plugins

Refer [How to write a Logstash input plugin] for input plugins.<br/>
Refer [How to write a Logstash codec plugin] for codec plugins.<br/>
Refer [How to write a Logstash filter plugin] for filter plugins.<br/>
Refer [How to write a Logstash output plugin] for output plugins.

Whatever the type of plugin, it will need to be a self-contained Ruby gem.

`logstash-plugin generate` creates a foundation for new Logstash plugins with files from templates.<br/>
It creates the standard directory structure, gemspec files, and dependencies a new plugin needs to get started.

The directory structure should look something like the following.<br/>
Replace `filter`/`filters` with `codec`/`codecs`, `input`/`inputs`, or `output`/`outputs` accordingly.

```sh
$ logstash-plugin generate --type 'filter' --name 'test'
[ … ]

$ tree 'logstash-filter-test'
logstash-filter-test
├── CHANGELOG.md
├── CONTRIBUTORS
├── DEVELOPER.md
├── docs
│   └── index.asciidoc
├── Gemfile
├── lib
│   └── logstash
│       └── filters
│           └── test.rb
├── LICENSE
├── logstash-filter-test.gemspec
├── Rakefile
├── README.md
└── spec
    ├── filters
    │   └── test_spec.rb
    └── spec_helper.rb
```

Plugins:

- Require parent classes defined in `logstash/filters/base` (or the appropriate plugin type's) and `logstash/namespace`.

  <details style="padding: 0 0 1rem 1rem">

  ```rb
  require "logstash/filters/base"
  require "logstash/namespace"
  ```

  </details>

- Shall be subclass of `LogStash::Filters::Base` (or the appropriate plugin type's).<br/>
  The class name shall closely mirror the plugin name.

  <details style="padding: 0 0 1rem 1rem">

  ```rb
  class LogStash::Filters::Test < LogStash::Filters::Base
  ```

  </details>

- Shall set their `config_name` to their own name inside the configuration block.

  <details style="padding: 0 0 1rem 1rem">

  ```rb
  class LogStash::Filters::Test < LogStash::Filters::Base
    config_name "test"
  ```

  </details>

- Include a configuration section defining as many parameters as needed to enable Logstash to process events.

  <details style="padding: 0 0 1rem 1rem">

  ```rb
  class LogStash::Filters::Test < LogStash::Filters::Base
    config_name "test"
    config :message, :validate => :string, :default => "Hello World!"
  ```

  </details>

- Must implement the `register` method, plus one or more other methods specific to the plugin's type.

Once ready:

1. Fix the `gemspec` file.
1. Build the Ruby gem.

  <details style="padding: 0 0 1rem 1rem">

  ```sh
  gem build
  ```

  </details>

1. Install the plugin in Logstash.

  <details style="padding: 0 0 1rem 1rem">

  ```sh
  $ logstash-plugin install 'logstash-filter-test-0.1.0.gem'
  Using bundled JDK: /usr/share/logstash/jdk
  OpenJDK 64-Bit Server VM warning: Option UseConcMarkSweepGC was deprecated in version 9.0 and will likely be removed in a future release.
  io/console on JRuby shells out to stty for most operations
  Validating logstash-filter-test-0.1.0.gem
  Installing logstash-filter-test
  ```

  </details>

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
[How to write a Logstash codec plugin]: https://www.elastic.co/docs/extend/logstash/codec-new-plugin
[How to write a Logstash filter plugin]: https://www.elastic.co/docs/extend/logstash/filter-new-plugin
[How to write a Logstash input plugin]: https://www.elastic.co/docs/extend/logstash/input-new-plugin
[How to write a Logstash output plugin]: https://www.elastic.co/docs/extend/logstash/output-new-plugin
[website]: https://www.elastic.co/logstash

<!-- Others -->
[how to debug your logstash configuration file]: https://logz.io/blog/debug-logstash/
