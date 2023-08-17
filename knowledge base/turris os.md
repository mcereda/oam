# Turris OS

Linux distribution based on top of OpenWrt. Check the [website] for more information.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [LED diodes settings](#led-diodes-settings)
   1. [Automatic overnight dimming](#automatic-overnight-dimming)
1. [Local DNS resolution](#local-dns-resolution)
1. [Static DHCP leases and hostnames](#static-dhcp-leases-and-hostnames)
1. [Containers](#containers)
   1. [Create new containers](#create-new-containers)
   1. [Assign containers a static IP address](#assign-containers-a-static-ip-address)
   1. [Start containers](#start-containers)
   1. [Execute a shell into containers](#execute-a-shell-into-containers)
   1. [Start containers at boot](#start-containers-at-boot)
   1. [Example: cfengine hub](#example-cfengine-hub)
   1. [Example: git server](#example-git-server)
   1. [Example: monitoring](#example-monitoring)
   1. [Example: pi-hole](#example-pi-hole)
1. [Hardening](#hardening)
1. [The SFP+ caged module](#the-sfp-caged-module)
   1. [Use the SFP module as a LAN port](#use-the-sfp-module-as-a-lan-port)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

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

# List available LXC container images.
# Default source is 'repo.turris.cz/lxc'.
lxc-create -n 'test' -t 'download'; lxc-destroy -n 'test'
lxc-create … -t 'download' -- --server 'images.linuxcontainers.org'

# Create LXC containers.
# Default source is 'repo.turris.cz/lxc'.
# Values are case sensitive and depend from what is on the server.
lxc-create -n 'alpine' -t 'download' -- -d 'Alpine' -r '3.18' -a 'armv7l'
lxc-create --name 'ubuntu-focal' --template 'download' -- \
  --server 'repo.turris.cz/lxc' \
  --dist 'Ubuntu' --release 'Focal' --arch 'armv7l'

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

## LED diodes settings

Permanent changes can be set in `/etc/config/rainbow`, the UCI configuration file.

The `rainbow` utility allows to change the color and set the status of each diode individually.<br/>
The setting are `disable` (off), `enable` (on) or `auto`; `auto` leaves the control of the diodes to the hardware, like blinking during data transfer and so on.

`rainbow`'s `brightness` subcommand uses numbers from 0 to 8, or from 0 to 255 if using the `-p` switch for higher precision.

### Automatic overnight dimming

Automatically adjust the intensity of LEDs using a cronjob to be able to see the state of individual devices during the day, but not to be dazzled by the diodes in the night.

Create the cron file in the `/etc/cron.d` directory:

```txt
# File /etc/cron.d/rainbow_night.
# Set the light intensity to the second lowest degree every day at 11 PM and set
# it back to maximum every day at 7 AM.
MAILTO=""   # avoid automatic logging of the output
0  23  *  *  *  root   rainbow brightness -p 3
0   7  *  *  *  root   rainbow brightness 5
```

## Local DNS resolution

Turris OS can answer DNS queries for local devices.

> Requires the _Network Settings_ > _DNS_ > _Enable DHCP clients in DNS_ option to be enabled.

## Static DHCP leases and hostnames

When assigning static DHCP leases LuCI **only requires** the IP and MAC addresses, while reForis will **also**:

- **require** a unique hostname for each entry
- set the lease time to _infinite_

Setting a hostname in an entry will make Turris OS resolve the IP address **only** with that given hostname (and **not** the name the host presents itself with).<br/>
Not setting a hostname in an entry will make Turris OS resolve the IP address with the name the host presents itself with.

CLI procedure:

```sh
uci add dhcp host
uci set dhcp.@host[-1].name='paracelsus'
uci set dhcp.@host[-1].mac='11:22:33:44:55:66'
uci set dhcp.@host[-1].ip='192.168.1.200'
uci commit 'dhcp'
reload_config
luci-reload
```

## Containers

Some packages are not available in `opkg`'s repository, but containers can replace them.<br/>
This is particularly useful to run services off the system which are not officially supported (like [Pi-hole]).

At the time of writing [LXC] is the only container runtime supported in Turris OS, and this guide will assume one is using it.<br/>
This requires the `lxc` package to be installed.

> It is highly suggested to use an [expansion disk](#hardware-upgrades) to store any container, but specially any one I/O heavy.

The procedure to have a working container is as follows:

1. [Create a new container](#create-new-containers).
1. Optionally, [assign it a static IP address](#assign-containers-a-static-ip-address).<br/>
   This is particularly suggested in case of services.
1. [Start the container](#start-containers).
1. [Execute a shell](#execute-a-shell-into-containers) to enter it and set it all up.<br/>
   See the configuration [examples](#examples) below.
1. Check all is working as expected.
1. If you changed the container's hostname from inside if, restart it for good measure.
1. Set the container to [start at boot](#start-containers-at-boot) if required.

Details for all actions are explained in the next sections.<br/>
Unless otherwise specified:

- All shell commands need to be executed from Turris OS.
- All WebUI actions need to be taken from LuCI.<br/>
  At the time of writing reForis does not have a way to manage containers.

### Create new containers

In shell:

```sh
# List available LXC container images.
# Default source is 'repo.turris.cz/lxc'.
lxc-create -n 'test' -t 'download'; lxc-destroy -n 'test'
lxc-create … -t 'download' -- --server 'images.linuxcontainers.org'

# Create LXC containers.
# Default source is 'repo.turris.cz/lxc'.
# Values are case sensitive and depend from what is on the server.
lxc-create -n 'pi-hole' -t 'download' -- -d 'Debian' -r 'Bullseye' -a 'armv7l'
lxc-create --name 'pi-hole' --template 'download' -- \
  --server 'repo.turris.cz/lxc' \
  --dist 'Ubuntu' --release 'Focal' --arch 'armv7l'
```

Using the WebUI:

1. Navigate to the _Services_ > _LXC Containers_ page.
1. In the _Create New Container_ section, give it a name and choose its template.
1. Click the _Create_ button under _Actions_.

### Assign containers a static IP address

In shell:

```sh
uci add dhcp host
uci set dhcp.@host[-1].name='pi-hole'
uci set dhcp.@host[-1].mac="$(grep 'hwaddr' '/srv/lxc/pi-hole/config' | sed 's/.*= //')"
uci set dhcp.@host[-1].ip='192.168.111.2'
uci commit 'dhcp'
reload_config
luci-reload
```

Using the WebUI:

1. Get the container's MAC address:

   1. Navigate to the _Services_ > _LXC Containers_ page.
   1. In the dropdown menu for the container, choose _configure_.
   1. Grab the MAC address from the textbox.

1. Navigate to the _Network_ > _DHCP and DNS_ page.
1. In the _Static Leases_ tab, assign a new lease to the container's MAC address.

### Start containers

In shell:

```sh
lxc-start --name 'pi-hole'

# Check it's running correctly.
lxc-info --name 'pi-hole'
```

Using the WebUI:

1. Navigate to the _Services_ > _LXC Containers_ page.
1. In the _Available Containers_ section, click the _Start_ button under _Actions_.

### Execute a shell into containers

In shell:

```sh
lxc-attach --name 'pi-hole'
```

### Start containers at boot

```sh
vim '/etc/config/lxc-auto'
```

```txt
config container
  option name pi-hole
  option timeout 60
```

### Example: cfengine hub

> CFEngine does not seem to support 32bits ARM processors anymore (but it does support arm64).<br/>
> Still, since I am using a 32bit processor this is not doable for me.

<details>
  <summary>Old installation test</summary>

  > This procedure assumes you are using an LXC container based on the Debian Bullseye image.

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

### Example: git server

> This procedure assumes you are using an LXC container based on the Debian Bullseye image.

```sh
# Set the correct hostname.
hostnamectl set-hostname 'git'

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

### Example: monitoring

> This procedure assumes you are using an LXC container based on the Debian Bullseye image.

```sh
# Set the correct hostname.
hostnamectl set-hostname 'monitoring'

# Install the requirements
DEBIAN_FRONTEND='noninteractive' apt-get install --assume-yes 'unattended-upgrades' 'wget'

# Stop installing recommended and suggested packages.
cat > /etc/apt/apt.conf.d/99norecommend << EOF
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF

# Add Grafana's repository with its key.
wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | tee -a /etc/apt/sources.list.d/grafana.list

# Install Prometheus and Grafana.
apt update
DEBIAN_FRONTEND='noninteractive' apt-get install --assume-yes 'grafana-enterprise' 'prometheus'

# Configure Prometheus and Grafana.
# See the '/docker/monitoring' example.

# Enable the services.
systemctl enable 'grafana-server.service'
systemctl enable 'prometheus.service'

# All done!
exit
```

### Example: pi-hole

> This procedure assumes you are using an LXC container based on the Debian Bullseye image.

See [Installing pi-hole on Turris Omnia], [Install Pi-hole] and [Pi-Hole on Turris Omnia] for details.

Install and configure Pi-hole in the container:

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
/etc/.pihole/pihole -up

# Set the router as the primary DNS server.
sed -E -i.bak 's|^#?\s*DNS\s*=\s*.*$|DNS=192.168.1.1|' '/etc/systemd/resolved.conf'

# Set Cloudflare as the fallback DNS server.
# Optional.
sed -E -i.bak 's|^#?\s*FallbackDNS\s*=\s*.*$|FallbackDNS=1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001 # Cloudflare|' '/etc/systemd/resolved.conf'

# Set the interface to ignore DNS lists given by the DHCP server.
cp '/etc/systemd/network/eth0.network' '/etc/systemd/network/eth0.network.bak'
cat >> '/etc/systemd/network/eth0.network' <<EOF
[DHCP]
UseDNS=false
EOF
```

Finish setting up the container as explained above.<br/>
Then, in Turris OS:

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

## Hardening

Suggestions:

- [SSH]:
  - Change the SSH port from the default `22` value.
  - Restrict login to specific IP addresses.
  - Restrict authentication options to keys.

## The SFP+ caged module

List of [supported SFP modules].

> The physical WAN port and the SFP module cage are wired to a single controller; when a SFP module is inserted, the physical WAN **port** **will be disabled**, and the virtual WAN interface will automatically be switched to the SFP module.

When the OS is installed, it will probably miss the SFP kernel modules.<br/>
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

   the SFP module is recognized and probably started working already right away.<br/>
   If, instead, no result has been returned:

   1. Make sure the SFP kernel modules are installed:

      ```sh
      opkg install 'kmod-spf'
      ```

   1. Reboot (for safety).
   1. Check the module has been recognized (see point 2 in this list).

### Use the SFP module as a LAN port

To use the SFP module as a LAN port, assign any other physical switch port to the virtual WAN interface to use that as the WAN connection and the SFP module in the LAN.

In the Foris web interface:

1. Go to _Network Settings_ > _Interfaces_.
1. Select the WAN interface.
1. In the dropdown _Network_ menu, change _WAN_ to _LAN_.
1. Select the LAN4 interface.
1. In the dropdown _Network_ menu, change _LAN_ to _WAN_.
1. Hit _Save_.

In the LuCI web interface:

1. Go to _Network_ > _Interfaces_.
1. In the _Interfaces_ tab, edit the WAN interface and assign the _lan4_ port to it.
1. In the _Devices_ tab, edit the _br-lan_ bridge device to include the port used by the SFP module (on mine, it was `eth2`).
1. Hit _Save & Apply_.

Using the CLI (yet to be tested):

```sh
uci set network.wan.device='lan4'
uci del_list network.br_lan.ports='lan4'
uci add_list network.br_lan.ports='eth2'
uci commit 'network'
reload_config
luci-reload
```

## Further readings

- [Website]
- Turris' [official documentation][docs]
- Turris' [wiki][turris wiki]
- [How to control LED diodes]
- [Factory reset on Turris Omnia]
- [Supported SFP modules]
- [Home NAS]
- [OpenWrt]
- [`opkg`][opkg]
- [UCI]
- [LXC]

## Sources

All the references in the [further readings] section, plus the following:

- [Install Pi-hole]
- [Pi-Hole on Turris Omnia]
- [Installing pi-hole on Turris Omnia]

<!--
  References
  -->

<!-- Upstream -->
[docs]: https://docs.turris.cz
[factory reset on turris omnia]: https://docs.turris.cz/hw/omnia/rescue-modes/
[home nas]: https://wiki.turris.cz/doc/en/howto/nas
[how to control led diodes]: https://wiki.turris.cz/doc/en/howto/led_settings
[supported sfp modules]: https://wiki.turris.cz/doc/en/public/sfp
[turris wiki]: https://wiki.turris.cz/doc/en/start
[website]: https://www.turris.com/turris-os/

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[lxc]: lxc.md
[openwrt]: openwrt.md
[opkg]: opkg.md
[pi-hole]: pi-hole.md
[ssh]: ssh.md
[uci]: uci.md

<!-- Others -->
[install pi-hole]: https://github.com/nminten/turris-omnia_documentation/blob/master/howtos/pihole.md
[installing pi-hole on turris omnia]: https://blog.weinreich.org/posts/2020/2020-05-02-turris-omnia-pihole/
[openwrt uci]: https://openwrt.org/docs/guide-user/base-system/uci
[pi-hole on turris omnia]: http://polster.github.io/2017/08/04/Pi-Hole-on-Turris.html
[pi-hole supported operating systems]: https://docs.pi-hole.net/main/prerequisites/#supported-operating-systems
