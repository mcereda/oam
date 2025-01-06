# Flog

Fake log generator for common log formats.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
go install 'github.com/mingrammer/flog'
docker run --rm -it 'mingrammer/flog'
brew install 'mingrammer/flog/flog'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Generate 1000 lines of logs to stdout.
flog

# Generate 200 lines of logs to stdout.
# Wait 1s for each line.
flog -n '200' -d '1'
flog --number '200' --delay '1s'

# Generate a single log file with 1000 lines of logs.
# Overwrite existing log files.
flog -t 'log' -w
flog --type 'log' --overwrite

# Generate a single gzipped log file with 3000 lines.
flog -t 'gz' -o 'log.gz' -n '3000'
flog --type 'gz' --output 'log.gz' --number '3000'

# Generate up to 10MB of logs.
# Split logs in files every 1MB.
# Use the 'apache combined' format.
flog -t 'log' -f 'apache_combined' -o 'web/log/apache.log' -b '10485760' -p '1048576'
flog --type 'log' --format 'apache_combined' --output 'web/log/apache.log' --bytes '10485760' --split-by '1048576'

# Generate logs in the rfc3164 format until killed.
flog -f 'rfc3164' -l
flog --format 'rfc3164' --loop
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

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/mingrammer/flog
[documentation]: https://website/docs/
[website]: https://website/

<!-- Others -->
