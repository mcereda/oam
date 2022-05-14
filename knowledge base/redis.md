# Redis

## TL;DR

```sh
# debug the server
redis-cli -h "${HOST}" -p "${PORT}" --user "${USERNAME}" --askpass MONITOR

# execute the commands from the master's container on kubernetes
kubectl exec redis-0 -- redis-cli MONITOR
```
