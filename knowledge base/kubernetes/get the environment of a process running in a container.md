# Get the environment of a process running in a container

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
cat /proc/${PID}/environ

# Container in kubernetes.
kubectl exec pod-name -- cat /proc/1/environ

# Only works if the onboard `ps` is not from busybox.
ps e -p $PID
```
## Further readings

- [Kubernetes]
- [`kubectl`][kubectl]

## Sources

All the references in the [further readings] section, plus the following:

- [Get the environment variables of running process in container]

<!-- internal references -->
[further readings]: #further-readings

<!-- external references -->
[get the environment variables of running process in container]: https://unix.stackexchange.com/a/412730
