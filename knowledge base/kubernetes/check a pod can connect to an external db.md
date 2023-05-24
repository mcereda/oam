# Check a Pod can connect to an external DB

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# access a test container
kubectl run --generator=run-pod/v1 --limits 'cpu=200m,memory=512Mi' --requests 'cpu=200m,memory=512Mi' --image alpine ${USER}-mysql-test -it -- sh

# install programs
apk --no-cache add mysql-client netcat-openbsd

# test plain connectivity
nc -vz -w3 10.0.2.15 3306

# test the client can connect
mysql --host 10.0.2.15 --port 3306 --user root
```

## Further readings

- [Kubernetes]
- [`kubectl`][kubectl]

## Sources

All the references in the [further readings] section, plus the following:

<!-- project's references -->
<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
[kubectl]: kubectl.md
[kubernetes]: README.md

<!-- external references -->
