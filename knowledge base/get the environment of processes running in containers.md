# Get the environment of processes running in containers

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# From a shell inside the container.
cat "/proc/${PID}/environ"

# In Kubernetes.
kubectl exec 'pod-name' -- cat '/proc/1/environ'

# This only works if the onboard `ps` is **not** the one from Busybox.
ps e -p "$PID"
```

## Further readings

- [Kubernetes]
- [`kubectl`][kubectl]

## Sources

All the references in the [further readings] section, plus the following:

- [Get the environment variables of running process in container]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[kubectl]: kubernetes/kubectl.md
[kubernetes]: kubernetes/README.md

<!-- Others -->
[get the environment variables of running process in container]: https://unix.stackexchange.com/a/412730
