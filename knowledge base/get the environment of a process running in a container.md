# Get the environment of a process running in a container

## TL;DR

```shell
cat /proc/${PID}/environ

# Container in kubernetes.
kubectl exec pod-name -- cat /proc/1/environ

# Only works if the onboard `ps` is not from busybox.
ps e -p $PID
```

## Sources

- [Get the environment variables of running process in container]

[get the environment variables of running process in container]: https://unix.stackexchange.com/a/412730
