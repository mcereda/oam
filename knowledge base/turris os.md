# Turris OS

Linux distribution based on top of [OpenWrt].\
Check the [website] for more information.

1. [TL;DR](#tldr)
1. [Local DNS resolution](#local-dns-resolution)
1. [Static DHCP leases and hostnames](#static-dhcp-leases-and-hostnames)
1. [Containers](#containers)
   1. [Get information about running containers](#get-information-about-running-containers)
   1. [Create new containers](#create-new-containers)
   1. [Assign containers a static IP address](#assign-containers-a-static-ip-address)
   1. [Start containers](#start-containers)
   1. [Get a shell into running containers](#get-a-shell-into-running-containers)
   1. [Start containers at boot](#start-containers-at-boot)
   1. [Examples](#examples)
1. [Hardening](#hardening)
1. [VLANs](#vlans)
1. [The SFP+ caged module](#the-sfp-caged-module)
   1. [Use the SFP module as a LAN port](#use-the-sfp-module-as-a-lan-port)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Using SQM might **slow down** network throughput instead of boosting performances.\
This is especially true on older, lower power devices. A Turris Omnia (ARMv7 Processor rev 1, v7l) dropped Internet
download speed from the _normal_ ~30 MBps to _at most_ 1.3 MBps when SQM was enabled.

<details>
  <summary>Usage</summary>

```sh
# Show settings.
uci show
uci show 'dhcp'

# Show what interface is the WAN.
uci show network.wan.device | cut -d "'" -f 2

# Configure a static IP address lease.
uci add dhcp host
uci set dhcp.@host[-1].name='hostname'
uci set dhcp.@host[-1].mac='11:22:33:44:55:66'
uci set dhcp.@host[-1].ip='192.168.1.2'

# Show changes to the settings.
uci changes
uci changes 'dhcp'

# Commit changes.
uci commit
uci commit 'dhcp'

# Reload the configuration.
# Necessary to reflect changes to the settings.
reload_config
luci-reload


# Get LEDs intensity.
rainbow brightness -q

# Set LEDs intensity.
# 0 to 8 normally, 0 to 255 using '-p'.
rainbow brightness '5'
rainbow brightness -p '100'


# Manage services.
/etc/init.d/sshd restart

# Gracefully reboot the device.
reboot

# Gracefully shutdown the device.
poweroff

# Get the current temperature.
cat '/sys/class/thermal/thermal_zone0/temp'
sensors


# List available LXC container images.
# Default source is 'repo.turris.cz/lxc'.
lxc-create --name 'test' --template 'download'; lxc-destroy --name 'test'
lxc-create -n 'test' -t 'download' -- --server 'images.linuxcontainers.org'; lxc-destroy --name 'test'

# Create LXC containers.
# Default source is 'repo.turris.cz/lxc'.
# Values are case sensitive and depend from what is on the server.
lxc-create --name 'alpine' --template 'download' -- --dist 'Alpine' --release '3.18' --arch 'armv7l'
lxc-create -n 'ubuntu-focal' -t 'download' -- \
  -s 'repo.turris.cz/lxc' \
  -d 'Ubuntu' -r 'Focal' -a 'armv7l'

# List containers.
lxc-ls

# Show information about running containers
lxc-info --name 'nextcloud'
lxc-info -n 'pi-hole'
lxc-info 'gitea' --ips

# Start containers.
lxc-start --name 'baikal'
lxc-start -n 'forgejo'
lxc-start 'gitea'

# Stop containers.
lxc-stop --name 'gitea'
lxc-stop -n 'forgejo'
lxc-stop 'nextcloud'

# Delete containers and their data.
lxc-destroy --name 'gitea'
lxc-destroy -n 'forgejo'
lxc-destroy 'nextcloud'


# List snapshots.
schnapps list

# Create snapshots.
schnapps create 'description'
schnapps create -t 'pre' 'description'

# Change snapshots' information.
schnapps modify '4' -t 'time' -d 'new description'

# Rollback to a snapshot.
schnapps rollback '2'

# Delete snapshots by number.
schnapps delete '3'

# Delete snapshots by type.
schnapps delete -t 'post'
```

</details>

## Local DNS resolution

Turris OS can answer DNS queries from devices in the local networks.\
This feature requires the _Network Settings_ > _DNS_ > _Enable DHCP clients in DNS_ option to be enabled.

## Static DHCP leases and hostnames

Assigning static DHCP leases from the shell or LuCI **only requires** the IP and MAC address pairs. Doing it from
reForis will **also**:

- **Require** a unique hostname for each lease.
- Set the lease time to _infinite_.

> [!important]
> Hosts might (and containers usually do) present themselves with a hostname when requesting an IP address.\
> This hostname will resolve to the IP address the DHCP provided.
>
> Specifying the hostname in a static DNS lease forces the resolver to answer with the static IP address **only** when
> the request comes in for **that** specific hostname (and **not** for _any_ other name the host might present itself
> with).\
> **Not** specifying the hostname in a static DNS lease allows the static IP address to resolve **by default** to any
> name the host presented itself with.

<details>
  <summary>Via the shell</summary>

```sh
uci add dhcp host
uci set dhcp.@host[-1].name='paracelsus'
uci set dhcp.@host[-1].mac='11:22:33:44:55:66'
uci set dhcp.@host[-1].ip='192.168.1.200'
uci commit 'dhcp'
reload_config
luci-reload
```

</details>

## Containers

Some packages are not available in [Opkg]'s repository, but containers can replace them.\
This is particularly useful to run unsupported, non-integrated, or otherwise custom services off the system (like
[Pi-hole]).

At the time of writing, [LXC] is the only container runtime _officially_ supported in Turris OS.\
It requires installing the `lxc` package.

> [!tip]
> Use an [expansion disk](turris%20omnia.md#hardware-upgrades) to store containers' data.\
> Recommended for any I/O heavy application, as this avoids wearing down the device's internal storage.

The _standard_ procedure to deploy a containerized service is as follows:

1. [Create a new container][create new containers].
1. \[_optional_] [Assign the container a static IP address][assign containers a static ip address].\
   Recommended in case of services.
1. [Start the container][start containers].
1. [Get a shell in the container][get a shell into running containers].
1. Configure the service inside the container.\
   See the examples below.
1. Check all is working as expected.
1. If changed the container's hostname from **inside** of it, restart it for good measure.
1. \[_optional_] Configure Turris OS to [start the container at boot][start containers at boot].

Details for all actions are explained in the next sections.\
Unless otherwise specified:

- All shell commands need to be executed from Turris OS.
- All webUI actions need to be taken from LuCI.\
  As of 2026-11-12, reForis does not allow to manage containers.

> [!tip] Mind the device's available resources.
> The main purpose of Turris OS is to run a router with (usually) limited resources.\
> Avoid overloading with too many heavy containers, and monitor usage.

### Get information about running containers

<details>
  <summary>Via the shell</summary>

```sh
lxc-info --name 'gitea'
lxc-info -n 'nextcloud'
lxc-info 'pi-hole'

# Only get the first IP address.
lxc-info --name 'forgejo' --ips --no-humanize | head -n '1'
```

</details>

### Create new containers

<details>
  <summary>Via the shell</summary>

```sh
# List available LXC container images.
# Default source is 'repo.turris.cz/lxc'.
lxc-create -n 'test' -t 'download'; lxc-destroy -n 'test'
lxc-create … -t 'download' -- --server 'images.linuxcontainers.org'; lxc-destroy -n 'test'

# Create LXC containers.
# Default source is 'repo.turris.cz/lxc'.
# Values are case sensitive and depend from what is on the server.
lxc-create -n 'pi-hole' -t 'download' -- -d 'Debian' -r 'Bullseye' -a 'armv7l'
lxc-create -n 'baikal' -t 'download' -- -d 'Alpine' -r '3.20' -a 'armv7l'
lxc-create --name 'pi-hole' --template 'download' -- \
  --server 'repo.turris.cz/lxc' \
  --dist 'Ubuntu' --release 'Focal' --arch 'armv7l'
```

</details>

<details>
  <summary>Using the webUI</summary>

1. Navigate to the _Services_ > _LXC Containers_ page.
1. In the _Create New Container_ section, give it a name and choose its template.
1. Click the _Create_ button under _Actions_.

</details>

### Assign containers a static IP address

<details>
  <summary>Via the shell</summary>

```sh
uci add dhcp host
uci set dhcp.@host[-1].name='pi-hole'
uci set dhcp.@host[-1].mac="$(grep 'hwaddr' '/srv/lxc/pi-hole/config' | sed 's/.*= //')"
uci set dhcp.@host[-1].ip='192.168.111.2'
uci commit 'dhcp'
reload_config
luci-reload
```

</details>

<details>
  <summary>Using the webUI</summary>

1. Get the container's MAC address:

   1. Navigate to the _Services_ > _LXC Containers_ page.
   1. In the dropdown menu for the container, choose _configure_.
   1. Grab the MAC address from the textbox.

1. Navigate to the _Network_ > _DHCP and DNS_ page.
1. In the _Static Leases_ tab, assign a new lease to the container's MAC address.

</details>

### Start containers

<details>
  <summary>Via the shell</summary>

```sh
lxc-start --name 'pi-hole'

# Check it's running correctly.
lxc-info --name 'pi-hole'
```

</details>

<details>
  <summary>Using the webUI</summary>

1. Navigate to the _Services_ > _LXC Containers_ page.
1. In the _Available Containers_ section, click the _Start_ button under _Actions_.

</details>

### Get a shell into running containers

<details>
  <summary>Via the shell</summary>

```sh
lxc-attach --name 'pi-hole'
lxc-attach -n 'nextcloud'
```

</details>

### Start containers at boot

<details>
  <summary>Via the shell</summary>

Add a section to `/etc/config/lxc-auto` for each container that should:

```sh
cat <<'EOF' >> '/etc/config/lxc-auto'
config container
  option name pi-hole
  option timeout 60
EOF
```

</details>

### Examples

<details>
  <summary>Baikal</summary>

> [!tip]
> Refer [baikal] and <https://sabre.io/baikal/install/>.

1. Create and start the container:

   ```sh
   lxc-create --name 'baikal' --template 'download' -- --dist 'Debian' --release 'Bookworm' --arch 'armv7l'
   lxc-start --name 'baikal'
   ```

1. Install and configure Baikal in the container:

   ```sh
   # Set the correct hostname.
   hostnamectl set-hostname 'baikal'
   sed -i 's/LXC_NAME/baikal/' '/etc/hosts'

   # Install baikal.
   # Also install `unattended-upgrades` to ease updates management.
   DEBIAN_FRONTEND='noninteractive' apt-get install --assume-yes --no-install-recommends \
     'apache2' 'ca-certificates' 'curl' 'php' 'php-sqlite3' 'php-sabre-dav' 'unattended-upgrades' 'unzip'
   a2dismod 'mpm_event'
   a2enmod 'rewrite' 'php*' 'ssl'
   systemctl restart 'apache2'
   openssl req -nodes \
     -newkey 'rsa:4096' -keyout '/etc/ssl/private/baikal.key' -out '/etc/ssl/private/baikal.crt' -x509 -days '365' \
     -subj '/C=NL/ST=North Holland/L=Amsterdam/O=Example Org/OU=Infra/CN=baikal.lan'
   curl -fsL -o '/var/www/baikal.zip' 'https://github.com/sabre-io/Baikal/releases/download/0.10.1/baikal-0.10.1.zip'
   unzip -ud '/var/www/' '/var/www/baikal.zip' && rm '/var/www/baikal.zip'
   chown -R 'www-data:www-data' '/var/www/baikal/Specific' '/var/www/baikal/config'
   cat <<EOF > '/etc/apache2/sites-enabled/010-baikal.conf'
   <VirtualHost *:443>

       DocumentRoot /var/www/baikal/html
       ServerName baikal.lan

       RewriteEngine on
       # Generally already set by global Apache configuration
       # RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
       RewriteRule /.well-known/carddav /dav.php [R=308,L]
       RewriteRule /.well-known/caldav  /dav.php [R=308,L]

       <Directory "/var/www/baikal/html">
           Options None
           # If you install cloning git repository, you may need the following
           # Options +FollowSymlinks
           AllowOverride None
           # Configuration for apache-2.4:
           Require all granted
           # Configuration for apache-2.2:
           # Order allow,deny
           # Allow from all
       </Directory>

       <IfModule mod_expires.c>
           ExpiresActive Off
       </IfModule>

       SSLEngine on
       SSLCertificateFile    /etc/ssl/private/baikal.crt
       SSLCertificateKeyFile /etc/ssl/private/baikal.key

   </VirtualHost>
   EOF
   ```

1. Connect to <https://baikal> to start the first-time installation wizard.
1. Test the service:

   ```sh
   curl -svvvko - --digest --user 'mark@baikal.lan:somePassword123' \
     --url 'https://baikal.lan/dav.php/calendars/mark@baikal.lan/default/'
   ```

1. Configure Turris OS to [start the container at boot][start containers at boot]:

   ```sh
   cat <<'EOF' >> '/etc/config/lxc-auto'
   config container
     option name baikal
     option timeout 60
   EOF
   ```

</details>

<details>
  <summary>Basic, stripped git server</summary>

1. Create and start the container.

   ```sh
   lxc-create --name 'git' --template 'download' -- --dist 'Debian' --release 'Bookworm' --arch 'armv7l'
   lxc-start --name 'git'
   ```

1. Install and configure the git server in the container:

   ```sh
   # Set the correct hostname.
   hostnamectl set-hostname 'git'
   sed -i 's/LXC_NAME/git/' '/etc/hosts'

   # Install Git and the SSH server.
   # Also install `unattended-upgrades` to ease updates management.
   DEBIAN_FRONTEND='noninteractive' apt-get install --assume-yes 'git' 'openssh-server' 'unattended-upgrades'

   # (Optionally) configure the SSH server.
   vim '/etc/ssh/sshd_config'
   systemctl restart 'ssh.service'

   # Create the git user.
   adduser 'git'

   # Set up passwordless authentication.
   mkdir '/home/git/.ssh' && sudo chmod '700' '/home/git/.ssh'
   touch '/home/git/.ssh/authorized_keys' && sudo chmod '600' '/home/git/.ssh/authorized_keys'
   echo 'ssh-…' >> '/home/git/.ssh/authorized_keys'

   # (Optionally) create the repositories' root directory.
   mkdir '/home/git/repositories'

   # Make sure the 'git' user has the correct permissions on the folders.
   chown -R 'git' '/home/git'

   # (Optionally) lock down the git user.
   # This will *prevent* clients to set their SSH key using `ssh-copy-id`.
   chsh 'git' -s "$(which 'git-shell')"

   # All done!
   exit
   ```

1. \[optionally] Configure Turris OS to [start the container at boot][start containers at boot].

</details>

<details>
  <summary>CFEngine hub</summary>

> [!warning] Review for `arm64` processors
> CFEngine does **not** seem to support 32 bits ARM processors anymore (but it does support `arm64`).

  <details style="padding-left: 1em;">
    <summary>Old installation test</summary>

  1. Create and start the container:

     ```sh
     lxc-create -n 'cfengine' -t 'download' -- -d 'Debian' -r 'Bullseye' -a 'armv7l'
     ```

  1. Install and configure CFEngine in the container:

     ```sh
     # Set the correct hostname.
     hostnamectl set-hostname 'cfengine'

     # Install CFEngine and the SSH server.
     # Also install `unattended-upgrades` to ease updates management.
     DEBIAN_FRONTEND='noninteractive' apt-get install --assume-yes 'cfengine3' 'openssh-server' 'unattended-upgrades'

     # Set up passwordless authentication.
     mkdir "${HOME}/.ssh" && chmod '700' "${HOME}/.ssh"
     echo 'ssh-…' >> "${HOME}/.ssh/authorized_keys" && chmod '600' "${HOME}/.ssh/authorized_keys"
     ```

  </details>

</details>

<details>
  <summary>Forgejo</summary>

1. Create and start the container:

   ```sh
   lxc-create --name 'forgejo' --template 'download' -- \
     --server 'images.linuxcontainers.org' --dist 'alpine' --release '3.24' --arch 'armhf'
   lxc-start --name 'forgejo' && lxc-info --name 'forgejo'
   ```

1. [Get a shell into the container][get a shell into running containers]:

   ```sh
   lxc-attach --name 'forgejo'
   ```

1. From within the container:

   1. Make sure the hostname is the expected one.\
      It should be already set correctly to the container's name.

      ```sh
      echo 'forgejo' > '/etc/hostname'
      hostname -F '/etc/hostname'
      ```

   1. [Setup Forgejo][forgejo / setup] for Alpine Linux:

      ```sh
      apk --no-cache add 'forgejo' 'forgejo-openrc'
      rc-update add 'forgejo' && rc-service 'forgejo' start
      ```

1. Connect to <http://forgejo:3000> to start the first-time installation wizard.
1. [Automate backups][forgejo / automate backups].
1. Configure Turris OS to [start the container at boot][start containers at boot]:

   ```sh
   cat <<'EOF' >> '/etc/config/lxc-auto'
   config container
     option name forgejo
     option timeout 60
   EOF
   ```

</details>

<details>
  <summary>Gitea</summary>

1. Create and start the container:

   ```sh
   lxc-create --name 'gitea' --template 'download' -- \
     --server 'images.linuxcontainers.org' --dist 'alpine' --release '3.24' --arch 'armhf'
   lxc-start --name 'gitea' && lxc-info --name 'gitea'
   ```

1. [Get a shell into the container][get a shell into running containers]:

   ```sh
   lxc-attach --name 'gitea'
   ```

1. From within the container:

   1. Make sure the hostname is the expected one.\
      It should be already set correctly to the container's name.

      ```sh
      echo 'gitea' > '/etc/hostname'
      hostname -F '/etc/hostname'
      ```

   1. Setup Gitea for Alpine Linux:

      ```sh
      apk --no-cache add 'gitea' 'gitea-openrc'
      rc-update add 'gitea' && rc-service 'gitea' start
      ```

1. Connect to <http://gitea:3000> to start the first-time installation wizard.
1. Configure Turris OS to [start the container at boot][start containers at boot]:

   ```sh
   cat <<'EOF' >> '/etc/config/lxc-auto'
   config container
     option name gitea
     option timeout 60
   EOF
   ```

</details>

<details>
  <summary>Monitoring</summary>

> [!warning]
> The stack used in this container could _**easily**_ overload the device.\
> Keep CPU and memory usage under control.

1. Create and start the container.

   ```sh
   lxc-create --name 'monitoring' --template 'download' -- --dist 'Debian' --release 'Bullseye' --arch 'armv7l'
   lxc-start --name 'monitoring' && lxc-info --name 'monitoring'
   ```

1. [Get a shell in the container][get a shell into running containers]:

   ```sh
   lxc-attach --name 'monitoring'
   ```

1. From within the container:

   1. Make sure the hostname is the expected one.\
      It should be already set correctly to the container's name.

      ```sh
      hostnamectl set-hostname 'monitoring'
      ```

   1. Configure the system:

      ```sh
      # Install the requirements
      DEBIAN_FRONTEND='noninteractive' apt-get install --assume-yes 'unattended-upgrades' 'wget'

      # Stop installing recommended and suggested packages.
      cat <<'EOF' > '/etc/apt/apt.conf.d/99norecommend'
      APT::Install-Recommends "0";
      APT::Install-Suggests "0";
      EOF
      ```

   1. Setup the monitoring components:

      ```sh
      # Add Grafana's repository with its key.
      wget -q -O '/usr/share/keyrings/grafana.key' 'https://apt.grafana.com/gpg.key'
      echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" \
      | tee -a '/etc/apt/sources.list.d/grafana.list'
      apt update

      # Install Prometheus and Grafana.
      DEBIAN_FRONTEND='noninteractive' apt-get install --assume-yes 'grafana-enterprise' 'prometheus'

      # Configure Prometheus and Grafana.
      # See the '/docker/monitoring' example at the root of this repo.

      # Enable the services.
      systemctl enable 'grafana-server.service'
      systemctl enable 'prometheus.service'
      ```

1. Configure Turris OS to [start the container at boot][start containers at boot]:

   ```sh
   cat <<'EOF' >> '/etc/config/lxc-auto'
   config container
     option name monitoring
     option timeout 60
   EOF
   ```

</details>

<details>
  <summary>Nextcloud</summary>

1. Create and start the container:

   ```sh
   lxc-create --name 'nextcloud' --template 'download' -- \
     --server 'images.linuxcontainers.org' --dist 'alpine' --release '3.24' --arch 'armhf'
   lxc-start --name 'nextcloud'
   ```

1. [Get a shell in the container][get a shell into running containers]:

   ```sh
   lxc-attach --name 'nextcloud'
   ```

1. From within the container:

   1. Make sure the hostname is the expected one.\
      It should be already set correctly to the container's name.

      ```sh
      echo 'nextcloud' > '/etc/hostname'
      hostname -F '/etc/hostname'
      ```

   1. [Setup Nextcloud for Alpine Linux][nextcloud / basic setup through alpine Linux packages, sqlite, and nginx with a self-signed certificate]:

      ```sh
      # Install required packages.
      apk --no-cache add \
        'nginx' 'openssl' \
        'php85-exif' 'php85-fpm' 'php85-pecl-apcu' 'php85-pecl-imagick' 'php85-sodium' 'php85-sysvsem' \
        'nextcloud33' 'nextcloud33-initscript' 'nextcloud33-occ' 'nextcloud33-sqlite'

      # Create a self-signed certificate.
      openssl req -x509 -nodes -days '365' -newkey 'rsa:4096' \
        -keyout '/etc/ssl/private/nextcloud-selfsigned.key' -out '/etc/ssl/certs/nextcloud-selfsigned.crt' \
        -subj '/CN=nextcloud' -addext "subjectAltName=DNS:nextcloud"

      # Configure the webserver.
      rm '/etc/nginx/http.d/default.conf'
      cat <<'EOF' > '/etc/nginx/http.d/nextcloud.conf'
      server {
          listen 80;
          listen [::]:80;
          server_name nextcloud;
          return 301  https://$host$request_uri;
      }
      server {
          listen 443 ssl;
          listen [::]:443 ssl;
          server_name nextcloud;

          root /usr/share/webapps/nextcloud;
          index index.php index.html index.htm;
          disable_symlinks off;

          ssl_certificate /etc/ssl/certs/nextcloud-selfsigned.crt;
          ssl_certificate_key /etc/ssl/private/nextcloud-selfsigned.key;
          ssl_session_timeout 5m;

          add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

          location / {
              try_files $uri $uri/ /index.html;
          }
          location ~ [^/]\.php(/|$) {
              fastcgi_split_path_info ^(.+?\.php)(/.*)$;
              if (!-f $document_root$fastcgi_script_name) { return 404; }
              fastcgi_pass unix:/run/nextcloud/fastcgi.sock;
              fastcgi_index index.php;
              include fastcgi.conf;
          }
          location ^~ /.well-known/carddav { return 301 /remote.php/dav/; }
          location ^~ /.well-known/caldav { return 301 /remote.php/dav/; }
          location ^~ /.well-known/webfinger { return 301 /index.php/.well-known/webfinger; }
          location ^~ /.well-known/nodeinfo { return 301 /index.php/.well-known/nodeinfo; }

          include mime.types;
          types { text/javascript mjs; }
      }
      EOF

      # Check the whole webserver configuration.
      nginx -t

      # Start the services.
      rc-update add nginx && rc-service nginx start
      rc-update add nextcloud && rc-service nextcloud start
      ```

1. Connect to <https://nextcloud> to start the first-time installation wizard.
1. Configure Turris OS to [start the container at boot][start containers at boot]:

   ```sh
   cat <<'EOF' >> '/etc/config/lxc-auto'
   config container
     option name nextcloud
     option timeout 60
   EOF
   ```

</details>

<details>
  <summary>Pi-hole</summary>

> [!tip]
> See [Installing pi-hole on Turris Omnia], [Install Pi-hole] and [Pi-Hole on Turris Omnia] for details.

1. Create and start the container:

   ```sh
   lxc-create -n 'pi-hole' -t 'download' -- -d 'Debian' -r 'Bullseye' -a 'armv7l'
   ```

1. Install and configure Pi-hole in the container:

   ```sh
   # Set the correct hostname.
   hostnamectl set-hostname 'pi-hole'

   # Install pi-hole.
   DEBIAN_FRONTEND='noninteractive' apt-get install --assume-yes 'ca-certificates' 'curl' 'unattended-upgrades'
   curl -sSL 'https://install.pi-hole.net' | bash

   # Follow the guided procedure.

   # Change the Web interface password, if needed.
   /etc/.pihole/pihole -a -p

   # Update pi-hole as a whole, if needed.
   /etc/.pihole/pihole updatePihole
   /etc/.pihole/pihole -up

   # Set the router as the primary DNS server.
   sed -E -i'.bak' 's|^#?\s*DNS\s*=\s*.*$|DNS=192.168.1.1|' '/etc/systemd/resolved.conf'

   # Set Cloudflare as the fallback DNS server.
   # Optional.
   sed -E -i'.bak' 's|^#?\s*FallbackDNS\s*=\s*.*$|FallbackDNS=1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001 # Cloudflare|' '/etc/systemd/resolved.conf'

   # Set the interface to ignore DNS lists given by the DHCP server.
   cp '/etc/systemd/network/eth0.network' '/etc/systemd/network/eth0.network.bak'
   cat >> '/etc/systemd/network/eth0.network' <<EOF
   [DHCP]
   UseDNS=false
   EOF
   ```

1. Connect to <http://pi-hole> to start the first-time installation wizard.
1. Configure Turris OS to [start the container at boot][start containers at boot].
1. Configure Turris OS to use Pi-hole as DNS server:

   ```sh
   # Distribute pi-hole as the primary DNS.
   # Keep the router as secondary.
   uci set dhcp.lan.dhcp_option='6,192.168.111.2,192.168.111.1'

   # The DNS server address in the IPv6 RA should be the container's ULA address
   # since the global routable IPv6 address tend to change daily.
   uci add_list dhcp.lan.dns="$(lxc-info --name pi-hole | grep -E 'IP.* f[cd]' | sed 's/IP: *//')"

   # Apply the new configuration.
   uci commit 'dhcp' && reload_config && luci-reload
   /etc/init.d/odhcpd restart
   /etc/init.d/dnsmasq restart
   ```

</details>

## Hardening

See [SSH hardening].

## VLANs

Refer to [LuCI VLAN setup] and [OpenWrt's VLANs section][openwrt / vlans].

Short for _Virtual Local Area Network_ and defined by the IEEE [802.1Q][ieee 802.1q] and [802.1ad][ieee 802.1ad]
standards.\
Used to keep network clients separated even when they are using the same shared physical network, by adding tags to
their frame headers.\
They require at least 2 devices that support VLAN features.

Interfaces that tag and receive tagged packets are _VLAN tagging interfaces_.\
They **must** be configured to use a specific VLAN ID and ports.

**Tagged** ports are meant to pass traffic for multiple VLANs, acting as links between switches (_trunk ports_).\
**Untagged** ports accept traffic for only a single VLAN, acting as links to end devices (_access ports_).

_Untagged_ ports will accept only **physically** incoming traffic that has **no** VLAN IDs (e.g. normal ethernet
traffic). These same ports will also **remove** VLAN IDs from **physically** outgoing packets.\
Each port can only be assigned as _untagged_ to exactly one VLAN ID.

Turris OS uses the Distributed Switch Architecture (DSA) to manage the switch. It enables creating VLAN interfaces
**directly** over physical interfaces.

Create VLAN interfaces for LAN ports on top of interfaces in the `lan` zone. Use interfaces in the `wan` or `wan6`
zones for traffic that does **not** pass through the LAN switch.

Configure VLAN interfaces in LuCI, in the `Network` > `Interfaces` menu, in the _Devices_ tab.

> [!tip]
> Prefer adding VLAN tagged interfaces to bridges in the format `<if>.X`, where `<if>` is the desired interface and `X`
> is the VLAN's ID (e.g. `lan0.12`, `wan0.50`, `eth0.42`).\
> This creates _driver-level_ VLANs, which allows for manual configuration.

> [!warning]
> TODO: continue

## The SFP+ caged module

List of [supported SFP modules].

> [!important]
> The physical WAN port and the SFP module cage are wired to a single controller; when a SFP module is inserted, the
> physical WAN **port** **will be disabled**, and the virtual WAN interface will automatically be switched to the SFP
> module.

When the OS is installed, it will probably miss the SFP kernel modules.\
Check the module is recognized by the system like so:

1. Insert the module in the cage.
1. Check the module has been recognized automatically:

   ```sh
   dmesg | grep 'sfp'
   ```

1. If the `grep` returned results:

   ```txt
   [   7.823007] sfp sfp: Host maximum power 3.0W
   [   8.167128] sfp sfp: Turris  RTSFP-10G  rev A  sn 1234567890  dc 123456
   ```

   the SFP module is recognized and probably started working already right away.\
   If, instead, no result has been returned:

   1. Make sure the SFP kernel modules are installed:

      ```sh
      opkg install 'kmod-spf'
      ```

   1. Reboot (for safety).
   1. Check the module has been recognized (see point 2 in this list).

### Use the SFP module as a LAN port

To use the SFP module as a LAN port, assign any other physical switch port to the virtual WAN interface to use that as
the WAN connection and the SFP module in the LAN.

<details>
  <summary>reForis webUI</summary>

1. Go to _Network Settings_ > _Interfaces_.
1. Select the WAN interface.
1. In the dropdown _Network_ menu, change _WAN_ to _LAN_.
1. Select the LAN4 interface.
1. In the dropdown _Network_ menu, change _LAN_ to _WAN_.
1. Hit _Save_.

</details>

<details>
  <summary>LuCI webUI</summary>

1. Go to _Network_ > _Interfaces_.
1. In the _Interfaces_ tab, edit the WAN interface and assign the _lan4_ port to it.
1. In the _Devices_ tab, edit the _br-lan_ bridge device to include the port used by the SFP module (on mine, it was
   `eth2`).
1. Hit _Save & Apply_.

</details>

<details>
  <summary>Via the shell</summary>

> [!warning]
> FIXME: needs testing.

```sh
uci set network.wan.device='lan4'
uci del_list network.br_lan.ports='lan4'
uci add_list network.br_lan.ports='eth2'
uci commit 'network'
reload_config
luci-reload
```

</details>

## Further readings

- [Website]
- Turris' official [documentation]
- Turris' [wiki]
- [How to control LED diodes]
- [Factory reset on Turris Omnia]
- [Supported SFP modules]
- [Home NAS]
- [OpenWrt]
- [Opkg]
- [UCI]
- [LXC]

### Sources

- [Install Pi-hole]
- [Pi-Hole on Turris Omnia]
- [Installing pi-hole on Turris Omnia]
- [Operating temperature]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Assign containers a static IP address]: #assign-containers-a-static-ip-address
[Create new containers]: #create-new-containers
[Get a shell into running containers]: #get-a-shell-into-running-containers
[Start containers]: #start-containers
[Start containers at boot]: #start-containers-at-boot

<!-- Knowledge base -->
[Baikal]: baikal.md
[Forgejo / Automate backups]: forgejo.md#automate-backups
[Forgejo / Setup]: forgejo.md#setup
[LXC]: lxc.md
[Nextcloud / Basic setup through Alpine Linux packages, SQlite, and Nginx with a self-signed certificate]: nextcloud.md#basic-setup-through-alpine-linux-packages-sqlite-and-nginx-with-a-self-signed-certificate
[OpenWrt / VLANs]: openwrt.md#vlans
[OpenWrt]: openwrt.md
[Opkg]: opkg.md
[Pi-hole]: pi-hole.md
[SSH hardening]: ssh.md#hardening
[UCI]: uci.md

<!-- Upstream -->
[Documentation]: https://docs.turris.cz
[Factory reset on Turris Omnia]: https://docs.turris.cz/hw/omnia/rescue-modes/
[Home NAS]: https://wiki.turris.cz/doc/en/howto/nas
[How to control LED diodes]: https://wiki.turris.cz/doc/en/howto/led_settings
[LuCI VLAN setup]: https://docs.turris.cz/basics/luci/vlan/luci-vlan/
[Operating temperature]: https://forum.turris.cz/t/operating-temperature/998
[Supported SFP modules]: https://wiki.turris.cz/doc/en/public/sfp
[Website]: https://www.turris.com/turris-os/
[Wiki]: https://wiki.turris.cz/doc/en/start

<!-- Others -->
[IEEE 802.1ad]: https://en.wikipedia.org/wiki/IEEE_802.1ad
[IEEE 802.1Q]: https://en.wikipedia.org/wiki/IEEE_802.1Q
[Install Pi-hole]: https://github.com/nminten/turris-omnia_documentation/blob/master/howtos/pihole.md
[Installing Pi-hole on Turris Omnia]: https://blog.weinreich.org/posts/2020/2020-05-02-turris-omnia-pihole/
[Pi-hole on Turris Omnia]: http://polster.github.io/2017/08/04/Pi-Hole-on-Turris.html
