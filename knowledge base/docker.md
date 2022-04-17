# Docker

## TL;DR

```shell
# run a container
docker run --rm hello-world

# run a container and gite it a volume and variables
docker run -d --name boinc --net=host --pid=host -v "${HOME}/boinc:/var/lib/boinc" -e BOINC_GUI_RPC_PASSWORD="123" -e BOINC_CMD_LINE_OPTIONS="--allow_remote_gui_rpc" boinc/client

# show containers status
docker ps --all

# cleanup
docker system prune
```

## Further readings

- [archlinux wiki]

[archlinux wiki]: https://wiki.archlinux.org/index.php/Docker
