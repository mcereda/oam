# NextCloud

1. [TL;DR](#tldr)
1. [Setup](#setup)
   1. [Basic setup through Alpine Linux packages, SQlite, and Nginx with a self-signed certificate](#basic-setup-through-alpine-linux-packages-sqlite-and-nginx-with-a-self-signed-certificate)
   1. [Using containers](#using-containers)
   1. [Kubernetes](#kubernetes)
   1. [Using Snap](#using-snap)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Redis is recommended to prevent file locking problems.

<details>
  <summary>Setup</summary>

  <details>
    <summary>Kubernetes, helm chart</summary>

  ```sh
  helm repo add 'nextcloud' 'https://nextcloud.github.io/helm/'
  helm repo update
  helm inspect values 'nextcloud/nextcloud' > 'values.yaml'
  helm upgrade -in 'nextcloud' --create-namespace --atomic 'nextcloud' 'nextcloud/nextcloud' -f 'values.yaml'
  ```

  </details>

</details>

<details>
  <summary>Usage</summary>

```sh
occ db:add-missing-indices
occ maintenance:repair --include-expensive
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
docker compose exec -ti -u 33 app /var/www/html/occ db:add-missing-indices
docker compose exec -ti -u 33 app /var/www/html/occ maintenance:repair --include-expensive
```

</details>

## Setup

### Basic setup through Alpine Linux packages, SQlite, and Nginx with a self-signed certificate

Refer to the [Alpine Linux wiki page][Alpine wiki / Nextcloud].

Bare minimal. Uses the available packages in the repository, **SQlite**, and **Nginx** with a **self-signed**
certificate responding to `nextcloud.lan`:

1. Install the required packages:

   ```sh
   apk --no-cache add \
     'nginx' 'openssl' \
     'php85-exif' 'php85-fpm' 'php85-pecl-apcu' 'php85-pecl-imagick' 'php85-sodium' 'php85-sysvsem' \
     'nextcloud33' 'nextcloud33-initscript' 'nextcloud33-occ' 'nextcloud33-sqlite'
   ```

1. Create the self-signed certificate:

   ```sh
   openssl req -x509 -nodes -days '365' -newkey 'rsa:4096' \
     -keyout '/etc/ssl/private/nextcloud-selfsigned.key' -out '/etc/ssl/certs/nextcloud-selfsigned.crt' \
     -subj '/CN=nextcloud.lan' -addext "subjectAltName=DNS:nextcloud.lan"
   ```

1. Configure the webserver:

   ```sh
   rm '/etc/nginx/http.d/default.conf'
   cat <<'EOF' > '/etc/nginx/http.d/nextcloud.lan.conf'
   server {
       listen       80;
       listen       [::]:80;
       server_name  nextcloud.lan;
       return       301  https://$host$request_uri;
   }
   server {
       listen       443 ssl;
       listen       [::]:443 ssl;
       server_name  nextcloud.lan;

       root              /usr/share/webapps/nextcloud;
       index             index.php index.html index.htm;
       disable_symlinks  off;

       ssl_certificate      /etc/ssl/certs/nextcloud-selfsigned.crt;
       ssl_certificate_key  /etc/ssl/private/nextcloud-selfsigned.key;
       ssl_session_timeout  5m;

       add_header  Strict-Transport-Security  "max-age=31536000; includeSubDomains"  always;

       location  /  {
           try_files $uri $uri/ /index.html;
       }
       location  ~  [^/]\.php(/|$)  {
           fastcgi_split_path_info ^(.+?\.php)(/.*)$;
           if (!-f $document_root$fastcgi_script_name)  { return 404; }
           fastcgi_pass  unix:/run/nextcloud/fastcgi.sock;
           fastcgi_index index.php;
           include       fastcgi.conf;
       }
       location  ^~ /.well-known/carddav    { return 301 /remote.php/dav/; }
       location  ^~ /.well-known/caldav     { return 301 /remote.php/dav/; }
       location  ^~ /.well-known/webfinger  { return 301 /index.php/.well-known/webfinger; }
       location  ^~ /.well-known/nodeinfo   { return 301 /index.php/.well-known/nodeinfo; }

       include mime.types;
       types { text/javascript mjs; }
   }
   EOF

   # Check the whole configuration.
   nginx -t
   ```

1. Start the services:

   ```sh
   rc-update add nginx     && rc-service nginx start
   rc-update add nextcloud && rc-service nextcloud start
   ```

1. Connect to the host (<https://nextcloud.lan> or via IP) to start the first-time installation wizard.
1. \[_recommended_] Add the self-signed certificate to one's devices so that applications will not refuse to contact it
   ([Android][Android / Install a certificate], [macOS][macOS / Add self-signed certificates to the keychain]).

### Using containers

Use environment variables to inform Nextcloud about internal configuration:

| Name                        | Default   | Description                                               |
| --------------------------- | --------- | --------------------------------------------------------- |
| `NEXTCLOUD_ADMIN_USER`      | (not set) | Name of the Nextcloud admin user                          |
| `NEXTCLOUD_ADMIN_PASSWORD`  | (not set) | Password for the Nextcloud admin user                     |
| `NEXTCLOUD_TRUSTED_DOMAINS` | (not set) | Optional space-separated list of domains                  |
| `REDIS_HOST`                | (not set) | Name of the Redis container, or FQDN of the Redis service |
| `REDIS_HOST_PORT`           | 6379      | Port for Redis services that run on non-standard ports    |

### Kubernetes

<details>
  <summary>Via the official helm chart</summary>

Installation:

1. Add the repository to Helm:

   ```sh
   helm repo add 'nextcloud' 'https://nextcloud.github.io/helm/'
   helm repo update
   ```

1. Get the default values from the updated chart

   ```sh
   helm inspect values 'nextcloud/nextcloud' > 'path/to/values.yml'
   ```

1. Edit the values file to your heart's content.
1. Install the server

   ```sh
   helm install --namespace 'nextcloud' 'nextcloud' 'nextcloud/nextcloud' --values 'path/to/values.yml'
   helm install --atomic \
     --create-namespace --namespace 'nextcloud' \
     'nextcloud' 'nextcloud/nextcloud' \
     --values 'path/to/values.yml'
   ```

Update the release (usually after changes are made to the values file):

```sh
helm upgrade --atomic \
  --namespace 'nextcloud' 'nextcloud' 'nextcloud/nextcloud' \
  --values 'path/to/values.yml'
```

Connect to the server:

```sh
export POD_NAME=$(\
  kubectl get pods --namespace 'nextcloud' \
    -l 'app.kubernetes.io/name=nextcloud,app.kubernetes.io/instance=nextcloud' \
    -o jsonpath='{.items[0].metadata.name}' \
)
kubectl --namespace 'nextcloud' port-forward "${POD_NAME}" '8080:80'
```

Default admin user: `admin`.\
Default admin password: `changeme`.

Update the external database connection parameters:

```sh
export \
  APP_HOST=127.0.0.1 \
  APP_PASSWORD=$(\
    kubectl get secret --namespace 'nextcloud' 'nextcloud' -o jsonpath="{.data.nextcloud-password}" \
    | base64 --decode \
  ) \
  EXTERNAL_DATABASE_HOST=10.20.30.40
helm upgrade 'nextcloud' 'nextcloud/nextcloud' \
  --set "nextcloud.password=$APP_PASSWORD,nextcloud.host=$APP_HOST" \
  --set 'service.type=ClusterIP' \
  --set "mariadb.enabled=false,externalDatabase.user=nextcloud,externalDatabase.database=nextcloud,externalDatabase.host=EXTERNAL_DATABASE_HOST"
```

Delete everything:

```sh
helm delete --namespace nextcloud nextcloud
kubectl delete namespace --ignore-not-found nextcloud
```

</details>

### Using Snap

To configure Nextcloud from `snap`:

1. Install `nextcloud.occ`.
1. Edit `/var/snap/nextcloud/current/nextcloud/config/config.php`.
1. Set the extra configuration options via the `snap set` command.

## Further readings

- [Website]
- [Self-hosting]
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

<!-- Knowledge base -->
[Android / Install a certificate]: android.md#install-a-certificate
[macOS / Add self-signed certificates to the keychain]: macos/README.md#add-self-signed-certificates-to-the-keychain
[self-hosting]: self-hosting.md

<!-- Upstream -->
[how to check if redis is used in nc]: https://help.nextcloud.com/t/how-to-check-if-redis-is-used-in-nc/22268/2
[docker image]: https://hub.docker.com/_/nextcloud/
[docker readme]: https://github.com/docker-library/docs/blob/master/nextcloud/README.md
[helm chart]: https://github.com/nextcloud/helm/tree/master/charts/nextcloud
[snap readme]: https://github.com/nextcloud/nextcloud-snap
[website]: https://nextcloud.com/

<!-- Others -->
[Alpine wiki / Nextcloud]: https://wiki.alpinelinux.org/wiki/Nextcloud
[how to install and configure nextcloud on ubuntu 18.04]: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-nextcloud-on-ubuntu-18-04
