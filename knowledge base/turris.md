# Turris OS

## TL;DR

```shell
# Get LEDs intensity.
rainbow get intensity

# Set LEDs intensity.
rainbow intensity 50
rainbow intensity 100
rainbow intensity 0

# Gracefully shutdown the device.
poweroff
```

## LED diodes settings

A permanent change of color can be set in the UCI configuration file `/etc/config/rainbow`.

The `rainbow` utility allows one to change the color and set the status of each diode individually. The setting are `disable` (off), `enable` (on) or `auto`; `auto` leaves the control of the diodes to the hardware, like blinking during data transfer and so on.

### Automatic overnight dimming

Should you want to see the state of individual devices during day but not to be dazzled by the diodes in the night, you can automatically adjust the intensity of LEDs using a cronjob.

Create a text file in the `/etc/cron.d` directory:

```text
# File /etc/cron.d/rainbow_night.
# Set the light intensity to the second lowest degree every day at 11 PM and set
# it back to maximum every day at 7 AM.
MAILTO=""   # avoid automatic logging of the output
0  23  *  *  *  root   rainbow intensity 5
0   7  *  *  *  root   rainbow intensity 100
```

## Containerized pi-hole

> Requires the `lxc` package to be installed.

See [Installing pi-hole on Turris Omnia], [Install Pi-hole] and [Pi-Hole on Turris Omnia] for details.

1. In Turris OS:

   ```shell
   # Create the LXC container.
   lxc-create --name pi-hole --template debian
   lxc-create --name pi-hole --template download --dist Ubuntu --release Focal --arch armv7l --server repo.turris.cz/lxc

   # Start it.
   lxc-start --name pi-hole

   # Check it's running correctly.
   lxc-info --name pi-hole

   # Get a shell to it.
   lxc-attach --name pi-hole
   ```

1. In the container:

   ```shell
   # Set the correct hostname.
   hostnamectl set-hostname pi-hole

   # Install pi-hole.
   DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes ca-certificates curl
   curl -sSL https://install.pi-hole.net | bash

   # Follow the guided procedure.
   ```

1. Again in Turris OS:

   ```shell
   # Configure pi-hole's static IP lease.
   uci add dhcp host
   uci set dhcp.@host[-1]=host
   uci set dhcp.@host[-1].name=pi-hole
   uci set dhcp.@host[-1].mac=`grep hwaddr /srv/lxc/pi-hole/config | sed 's/.*= //'`
   uci set dhcp.@host[-1].ip=192.168.111.2

   # Distribute pi-hole as primary DNS.
   uci set dhcp.lan.dhcp_option='6,192.168.111.2'
   uci add_list dhcp.lan.dns=`lxc-info --name pi-hole | grep "IP.* f[cd]" | sed "s/IP: *//"`

   # Apply the new configuration.
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

> **Warning:** when LEDs turn red, it means that some highly sensitive operation is in process and data may be corrupted if it is interupted. Try not to reset router during the proccess or you might end up with corrupted filesystem. That one can be fixed using mode 4 but with complete data loss.

## Further readings

- [Led settings][wiki led settings] on the [wiki][turris wiki]
- [opkg]

[opkg]: opkg.md
[wiki led settings]: https://wiki.turris.cz/doc/en/howto/led_settings

## Sources

- Turris [official documentation][docs]
- Turris [wiki][turris wiki]
- [Install Pi-hole]
- [Pi-Hole on Turris Omnia]
- [Installing pi-hole on Turris Omnia]
- [Factory reset on Turris Omnia]

[docs]: https://docs.turris.cz
[factory reset on turris omnia]: https://docs.turris.cz/hw/omnia/rescue-modes/
[install pi-hole]: https://github.com/nminten/turris-omnia_documentation/blob/master/howtos/pihole.md
[installing pi-hole on turris omnia]: https://blog.weinreich.org/posts/2020/2020-05-02-turris-omnia-pihole/
[openwrt uci]: https://openwrt.org/docs/guide-user/base-system/uci
[pi-hole on turris omnia]: http://polster.github.io/2017/08/04/Pi-Hole-on-Turris.html
[turris wiki]: https://wiki.turris.cz/doc/en/start
