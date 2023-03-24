# Turris OS

Linux distribution based on top of OpenWrt. Check the [website] for more information.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [LED diodes settings](#led-diodes-settings)
   1. [Automatic overnight dimming](#automatic-overnight-dimming)
1. [Local DNS resolution](#local-dns-resolution)
1. [Static DHCP leases and hostnames](#static-dhcp-leases-and-hostnames)
1. [Containerized pi-hole](#containerized-pi-hole)
1. [Factory reset](#factory-reset)
1. [Hardware upgrades](#hardware-upgrades)
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

# Gracefully reboot the device.
reboot

# Gracefully shutdown the device.
poweroff

# Create LXC containers.
lxc-create --name 'ubuntu-focal' --template 'download' -- --dist 'Ubuntu' --release 'Focal' --arch 'armv7l' --server 'repo.turris.cz/lxc'
lxc-create … -t 'download' -- --dist 'debian' --release 'bullseye' --arch 'armhf' --server 'images.linuxcontainers.org'

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

A permanent change of color can be set in the UCI configuration file `/etc/config/rainbow`.

The `rainbow` utility allows one to change the color and set the status of each diode individually. The setting are `disable` (off), `enable` (on) or `auto`; `auto` leaves the control of the diodes to the hardware, like blinking during data transfer and so on.

`rainbow`'s `brightness` subcommand uses numbers from 0 to 8, or from 0 to 255 if using the `-p` switch for higher precision.

### Automatic overnight dimming

Should you want to see the state of individual devices during day but not to be dazzled by the diodes in the night, you can automatically adjust the intensity of LEDs using a cronjob.

Create a text file in the `/etc/cron.d` directory:

```text
# File /etc/cron.d/rainbow_night.
# Set the light intensity to the second lowest degree every day at 11 PM and set
# it back to maximum every day at 7 AM.
MAILTO=""   # avoid automatic logging of the output
0  23  *  *  *  root   rainbow brightness 1
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

## Containerized pi-hole

> Requires the `lxc` package to be installed.

> Suggested the use of an [expansion disk](#hardware-upgrades).

See [Installing pi-hole on Turris Omnia], [Install Pi-hole] and [Pi-Hole on Turris Omnia] for details.

Choose one of Pi-hole's [supported operating systems][pi-hole supported operating systems], then follow this procedure:

1. In Turris OS:

   ```sh
   # Create the LXC container (pick one).
   lxc-create --name 'pi-hole' --template 'download' -- --dist 'debian' --release 'bullseye' --arch 'armhf' --server 'images.linuxcontainers.org'

   # Configure pi-hole's static IP lease.
   uci add dhcp host
   uci set dhcp.@host[-1].name='pi-hole'
   uci set dhcp.@host[-1].mac="$(grep hwaddr /srv/lxc/pi-hole/config | sed 's/.*= //')"
   uci set dhcp.@host[-1].ip='192.168.111.2'
   uci commit 'dhcp'
   reload_config
   luci-reload

   # Start it.
   lxc-start --name 'pi-hole'

   # Check it's running correctly.
   lxc-info --name 'pi-hole'

   # Get a shell to it.
   lxc-attach --name 'pi-hole'
   ```

1. In the container:

   ```sh
   # Set the correct hostname, if different from what is expected.
   hostnamectl set-hostname 'pi-hole'

   # Install pi-hole.
   DEBIAN_FRONTEND='noninteractive' apt-get install --assume-yes 'ca-certificates' 'curl'
   curl -sSL 'https://install.pi-hole.net' | bash

   # Follow the guided procedure.

   # Change the Web interface password, if needed.
   /etc/.pihole/pihole -a -p
   ```

1. Check all is working as expected.
1. Again in Turris OS:

   ```sh
   # Start pi-hole at boot
   vim '/etc/config/lxc-auto'
   ```

   ```text
   config container
       option name pi-hole
       option timeout 60
   ```

   ```sh
   # Distribute pi-hole as the primary DNS.
   # Keep the router as secondary.
   uci set dhcp.lan.dhcp_option='6,192.168.111.2,192.168.111.1'

   # The dns server address in the IPv6 RA should be the container's ULA address
   # since the global routable IPv6 address tend to change daily.
   uci add_list dhcp.lan.dns="$(lxc-info --name pi-hole | grep -E 'IP.* f[cd]' | sed 's/IP: *//')"

   # Apply the new configuration.
   uci commit 'dhcp' && reload_config && luci-reload
   /etc/init.d/odhcpd restart
   /etc/init.d/dnsmasq restart
   ```

## Factory reset

Keep pressed the reset button on the back panel and wait for LEDs to indicate the number of the desired mode, then release the reset button.

The LEDs are used as a counter, with the number of lid LEDs (regardless of the color) indicating the reset mode the router will reboot into. The LEDs will transition from green to red, and when the last LED turns red the next LED will light up and the counter is incremented. When the counter reaches 12 (the total number of LEDs), it will start again from 1.

When the reset button is released, the LED counter will blink three times to confirm the selected reset mode. If the selected mode is different from the required one, just press the reset button again and start the mode selection process again.

Available reset modes are:

- 1 LED: standard (re)boot
- 2 LEDs: rollback to latest snapshot
- 3 LEDs: rollback to factory reset
- 4 LEDs: re-flash the router from a flash drive
- 5 LEDs: enable an insecure SSH on 192.168.1.1 (Omnia 2019 and newer)
- 6 LEDs: re-flash from the Internet (Omnia 2019 and newer)
- 7 LEDs: start a rescue shell

> **Tip:** release the reset button immediately after the required number of LEDs starts shining (regardless of the color). Do not unnecessarily prolong holding the reset button when the last LED is lit. By doing this you decrease a chance of accidentally transitioning to the next mode at the same moment when the button is released.

After the selected mode indication is performed, all LEDs will turn blue for a moment and then a light wave indicates the start the first stage boot during which LEDs turn green.

> **Warning:** when LEDs turn red, it means that some highly sensitive operation is in process and data may be corrupted if it is interrupted. Try not to reset router during the process or you might end up with corrupted filesystem. That one can be fixed using mode 4 but with complete data loss.

## Hardware upgrades

Most compatible upgrades are available on [Discomp].

[Supported SFP modules].

| Type                 | Product                                      |
| -------------------- | -------------------------------------------- |
| mSATA expansion disk | [Kingston 1024G SSD KC600 SATA3 mSATA]       |
| SFP module           | [Turris RTROM01-RTSF-10G SFP+ copper module] |
| WiFi                 | [Turris Omnia WiFi 6 upgrade kit]            |

## The SFP+ caged module

> The physical WAN port and the SFP module cage are wired to a single controller; when a SFP module is inserted, the physical WAN **port** **will be disabled**, and the virtual WAN interface will automatically be switched to the SFP module.

When the OS is installed, it will probably miss the SFP kernel modules.<br/>
Check the module is recognized by the system like so:

1. Insert the module in the cage.
1. Check the module has been recognized automatically:

   ```sh
   dmesg | grep 'sfp'
   ```

1. If the `grep` returned results:

   ```text
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
- [opkg]
- [uci]

## Sources

All the references in the [further readings] section, plus the following:

- [Install Pi-hole]
- [Pi-Hole on Turris Omnia]
- [Installing pi-hole on Turris Omnia]

<!-- project's references-->
[docs]: https://docs.turris.cz
[factory reset on turris omnia]: https://docs.turris.cz/hw/omnia/rescue-modes/
[how to control led diodes]: https://wiki.turris.cz/doc/en/howto/led_settings
[supported sfp modules]: https://wiki.turris.cz/doc/en/public/sfp
[turris wiki]: https://wiki.turris.cz/doc/en/start
[website]: https://www.turris.com/turris-os/

<!-- internal references -->
[further readings]: #further-readings
[opkg]: opkg.md
[uci]: uci.md

<!-- external references -->
[discomp]: https://www.discomp.cz/
[install pi-hole]: https://github.com/nminten/turris-omnia_documentation/blob/master/howtos/pihole.md
[installing pi-hole on turris omnia]: https://blog.weinreich.org/posts/2020/2020-05-02-turris-omnia-pihole/
[kingston 1024g ssd kc600 sata3 msata]: https://www.amazon.com/gp/product/B08ZNRTDD8/
[openwrt uci]: https://openwrt.org/docs/guide-user/base-system/uci
[pi-hole on turris omnia]: http://polster.github.io/2017/08/04/Pi-Hole-on-Turris.html
[pi-hole supported operating systems]: https://docs.pi-hole.net/main/prerequisites/#supported-operating-systems
[turris omnia wifi 6 upgrade kit]: https://www.discomp.cz/turris-omnia-wi-fi-6-upgrade-kit_d120048.html
[turris rtrom01-rtsf-10g sfp+ copper module]: https://www.discomp.cz/turris-rtrom01-rtsf-10g-sfp-metalicky-modul-10-gbps-rj45_d113354.html
