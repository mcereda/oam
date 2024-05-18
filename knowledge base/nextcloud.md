# NextCloud

Redis is recommended to prevent file locking problems.

## Table of contents <!-- omit in toc -->

1. [Containerized](#containerized)
   1. [Official helm chart](#official-helm-chart)
1. [Snappy](#snappy)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Containerized

Use environment variables to inform Nextcloud about internal configuration:

| Name                        | Default   | Description                                               |
|-----------------------------|-----------|-----------------------------------------------------------|
| `NEXTCLOUD_ADMIN_USER`      | (not set) | Name of the Nextcloud admin user                          |
| `NEXTCLOUD_ADMIN_PASSWORD`  | (not set) | Password for the Nextcloud admin user                     |
| `NEXTCLOUD_TRUSTED_DOMAINS` | (not set) | Optional space-separated list of domains                  |
| `REDIS_HOST`                | (not set) | Name of the Redis container, or FQDN of the Redis service |
| `REDIS_HOST_PORT`           | 6379      | Port for Redis services that run on non-standard ports    |

### Official helm chart

Installation:

1. add the repository to helm

   ```sh
   helm repo add nextcloud https://nextcloud.github.io/helm/
   helm repo update
   ```

1. get the default values from the updated chart

   ```sh
   helm inspect values nextcloud/nextcloud > "$(git rev-parse --show-toplevel)/kubernetes/helm/nextcloud/values.yaml"
   ```

1. edit the values to your heart's content
1. install the server

   ```sh
   helm install --namespace nextcloud nextcloud nextcloud/nextcloud --values kubernetes/helm/nextcloud/values.dev.yaml
   helm install --atomic --create-namespace --namespace nextcloud nextcloud nextcloud/nextcloud --values kubernetes/helm/nextcloud/values.dev.yaml
   ```

Update the release after changes are made to the values:

```sh
helm upgrade --atomic --namespace nextcloud nextcloud nextcloud/nextcloud --values kubernetes/helm/nextcloud/values.dev.yaml
```

Connect to the server (install with default values):

```sh
export POD_NAME=$(kubectl get pods --namespace nextcloud -l "app.kubernetes.io/name=nextcloud,app.kubernetes.io/instance=nextcloud" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace nextcloud port-forward "${POD_NAME}" 8080:80
```

default admin user: `admin`
default admin password: `changeme`

Update the external database connection parameters (install with default values):

```sh
export APP_HOST=127.0.0.1
export APP_PASSWORD=$(kubectl get secret --namespace nextcloud nextcloud -o jsonpath="{.data.nextcloud-password}" | base64 --decode)
helm upgrade nextcloud nextcloud/nextcloud \
  --set nextcloud.password=$APP_PASSWORD,nextcloud.host=$APP_HOST,service.type=ClusterIP,mariadb.enabled=false,externalDatabase.user=nextcloud,externalDatabase.database=nextcloud,externalDatabase.host=YOUR_EXTERNAL_DATABASE_HOST
```

Delete everything:

```sh
helm delete --namespace nextcloud nextcloud
kubectl delete namespace --ignore-not-found nextcloud
```

## Snappy

To configure Nextcloud from `snap`:

- use `nextcloud.occ`
- edit `/var/snap/nextcloud/current/nextcloud/config/config.php`
- use the extra configuration options via the `snap set` command

## Further readings

- [Website]
- The docker version's [README][docker readme]
- The snap version's [README][snap readme]
- [How to install and configure Nextcloud on Ubuntu 18.04]

Providers:

- [The Good Cloud](https://thegood.cloud)

### Sources

- [Docker image]
- [Helm chart]
- [How to check if Redis is used in NC]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[how to check if redis is used in nc]: https://help.nextcloud.com/t/how-to-check-if-redis-is-used-in-nc/22268/2
[docker image]: https://hub.docker.com/_/nextcloud/
[docker readme]: https://github.com/docker-library/docs/blob/master/nextcloud/README.md
[helm chart]: https://github.com/nextcloud/helm/tree/master/charts/nextcloud
[snap readme]: https://github.com/nextcloud/nextcloud-snap
[website]: https://nextcloud.com/

<!-- Others -->
[how to install and configure nextcloud on ubuntu 18.04]: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-nextcloud-on-ubuntu-18-04
