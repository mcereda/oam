# Monitoring solution

Leverages Prometheus and Grafana.

1. [Pre-flight operations](#pre-flight-operations)
1. [Runtime operations](#runtime-operations)
1. [Further readings](#further-readings)

## Pre-flight operations

For example purposes, the host running them will also run the Node Exporter to provide data.<br/>
Since the Node Exporter container runs in host mode, the host's IP or FQDN must be set in
[Prometheus' configuration file] for this to work.

The configuration provided needs to be readable from the processes using it.<br/>
Fix files' permissions:

```sh
# From the containers.
docker compose run --rm --user 'root' --entrypoint chown 'grafana' -Rv 'grafana' '/etc/grafana' '/var/lib/grafana'
docker compose run --rm --user 'root' --entrypoint chown 'prometheus' -Rv 'nobody:nobody' '/etc/prometheus'

# Locally.
sudo chown -R '472:0' 'grafana'
sudo chown -R '65534:65534' 'prometheus'
```

## Runtime operations

Default credentials for Grafana: `admin` - `admin`.<br/>
Will be requested to change them upon first login.

## Further readings

- [Grafana]
- [Prometheus]
- [ERROR - Deploy - Error response from daemon: linux mounts: path / is mounted on / but it is not a shared or slave mount]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[grafana]: ../../knowledge%20base/grafana.md
[prometheus]: ../../knowledge%20base/prometheus/README.md

<!-- Files -->
[prometheus' configuration file]: prometheus/prometheus.yml

<!-- Others -->
[error - deploy - error response from daemon: linux mounts: path / is mounted on / but it is not a shared or slave mount]: https://github.com/prometheus/node_exporter/issues/2002#issuecomment-802753422
