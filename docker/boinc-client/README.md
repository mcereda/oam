# Boinc client on Docker

> See my custom image at [container-image-boinc-client](https://gitlab.com/mckie/container-image-boinc-client).

## Table of contents <!-- omit in toc -->

1. [Parameters](#parameters)
1. [Docker Compose](#docker-compose)
1. [Attach to an account manager](#attach-to-an-account-manager)
1. [TODO](#todo)
1. [Sources](#sources)

## Parameters

Parameter | Type | Default | Function
--- | --- | --- | ---
`BOINC_CMD_LINE_OPTIONS` | Environment Variable | `"--allow_remote_gui_rpc"` | The `--allow_remote_gui_rpc` command-line option allows connecting to the client with any IP address. If you don't want that, you can remove this parameter, but you have to use the `BOINC_REMOTE_HOST="IP"` environment variable
`BOINC_GUI_RPC_PASSWORD` | Environment Variable | `"123"` | The password you will need to use when you connect to the BOINC client
`BOINC_REMOTE_HOST` | Environment Variable | `"127.0.0.1"` | (Optional) Replace the IP with your IP address. In this case you can connect to the client only from this IP
`TZ`| Environment Variable | `"Europe/London"` | (Optional) Specify a time zone. The default is UTC +0
`/opt/appdata/boinc:/var/lib/boinc` | Path or Volume | | The path where you wish BOINC to store its configuration data
`--pid=host` | Docker Run Option | | (Optional) Share the host's process namespace, basically allowing processes within the container to see all of the processes on the system. Allows boinc to determine nonboinc processes for CPU percentages and exclusive applications.

## Docker Compose

You can create the following docker-compose.yml file and from within the same directory run the client with docker-compose up -d to avoid the longer command from above.

```yaml
version: '2'
services:

  boinc:
    image: boinc/client
    container_name: boinc
    restart: always
    network_mode: host
    pid: host
    volumes:
      - /opt/appdata/boinc:/var/lib/boinc
    environment:
      - BOINC_GUI_RPC_PASSWORD=123
      - BOINC_CMD_LINE_OPTIONS=--allow_remote_gui_rpc
```

## Attach to an account manager

```sh
boinccmd --acct_mgr attach https://bam.boincstats.com $USER $PASSWORD
```

## TODO

- automatic account manager attach after boot

## Sources

- [Github]
- [Docker Hub]

<!--
  References
  -->

<!-- Upstream -->
[docker hub]: https://hub.docker.com/r/boinc/client
[github]: https://github.com/BOINC/boinc-client-docker
