# OpenWrt

Linux operating system targeting embedded devices, providing a fully writable filesystem with package management.

## Table of contents <!-- omit in toc -->

1. [Monitoring](#monitoring)
   1. [Prometheus](#prometheus)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Monitoring

### Prometheus

On the router:

```sh
opkg install \
  'prometheus-node-exporter-lua' \
  'prometheus-node-exporter-lua-nat_traffic' \
  'prometheus-node-exporter-lua-netstat' \
  'prometheus-node-exporter-lua-openwrt' \
  'prometheus-node-exporter-lua-wifi' \
  'prometheus-node-exporter-lua-wifi_stations'
sed -E -i'.bak' "s/(option listen_interface) 'loopback'/\1 'lan'/" /etc/config/prometheus-node-exporter-lua
/etc/init.d/prometheus-node-exporter-lua start
curl 'router.fqdn:9100/metrics'
```

In Prometheus'configuration file:

```yml
scrape_configs:
  - job_name: OpenWrt
    static_configs:
      - targets: [ 'router.fqdn:9100' ]
```

Dashboard for grafana: [11147-openwrt](https://grafana.com/grafana/dashboards/11147-openwrt/).

## Further readings

- [Website]
- [`opkg`][opkg]
- [UCI]
- [LXC]
- [Turris OS]

## Sources

All the references in the [further readings] section, plus the following:

- [How I monitor my OpenWrt router with Grafana Cloud and Prometheus]

<!--
  References
  -->

<!-- Upstream -->
[website]: https://openwrt.org/

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[lxc]: lxc.md
[opkg]: opkg.md
[turris os]: turris%20os.md
[uci]: uci.md

<!-- Others -->
[how i monitor my openwrt router with grafana cloud and prometheus]: https://grafana.com/blog/2021/02/09/how-i-monitor-my-openwrt-router-with-grafana-cloud-and-prometheus/
