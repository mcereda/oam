# pganalyze Collector

Periodically queries configured databases and sends metrics and metadata (as _snapshots_) to the Pganalyze app.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Generic installation via magic script.
curl 'https://packages.pganalyze.com/collector-install.sh' | bash

# Change the configuration file and reload the collector's settings.
vim '/etc/pganalyze-collector.conf' && pganalyze-collector --test --reload \
&& systemctl status 'pganalyze-collector' && journalctl -xefu 'pganalyze-collector'
```

</details>

## Further readings

- [Main repository]
- [Documentation]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[documentation]: https://pganalyze.com/docs/collector/
[main repository]: https://github.com/pganalyze/collector

<!-- Others -->
