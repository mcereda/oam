# Turris Omnia

1. [Factory reset](#factory-reset)
1. [LED diodes settings](#led-diodes-settings)
   1. [Automatic overnight dimming](#automatic-overnight-dimming)
1. [Hardware upgrades](#hardware-upgrades)
1. [Further readings](#further-readings)

## Factory reset

Keep pressed the reset button on the back panel and wait for LEDs to indicate the number of the desired mode, then
release the reset button.

The LEDs are used as a counter, with the number of lid LEDs (regardless of the color) indicating the reset mode the
router will reboot into.\
The LEDs will transition from green to red, and when the last LED turns red the next LED will light up and the counter
is incremented.\
When the counter reaches 12 (the total number of LEDs), it will start again from 1.

When the reset button is released, the LED counter will blink three times to confirm the selected reset mode.\
If the selected mode is different from the required one, just press the reset button again and start the mode selection
process again.

Available reset modes are:

- 1 LED: standard (re)boot
- 2 LEDs: rollback to latest snapshot
- 3 LEDs: rollback to factory reset
- 4 LEDs: re-flash the router from a flash drive
- 5 LEDs: enable an insecure SSH on 192.168.1.1 (Omnia 2019 and newer)
- 6 LEDs: re-flash from the Internet (Omnia 2019 and newer)
- 7 LEDs: start a rescue shell

> [!tip]
> Release the reset button immediately after the required number of LEDs starts shining (regardless of the
> color).
>
> Do **not** unnecessarily prolong holding the reset button when the last LED is lit.\
> Holding it for too long just increases the chance of accidentally transitioning to a successive mode at the moment one
> releases the button.

After the selected mode indication is performed, all LEDs will turn blue for a moment and then a light wave indicates
the start the first stage boot during which LEDs turn green.

> [!warning]
> The LEDs turn red when some highly sensitive operation is in process. Data may be corrupted if this is interrupted.\
> Avoid resetting the router during the process, or one might end up with a corrupted filesystem. In this case, only
> mode 4 can fix the issue. It means complete data loss.

## LED diodes settings

If using [Turris OS], permanent changes can be set in `/etc/config/rainbow`, the UCI configuration file.

The `rainbow` utility allows to change the color and set the status of each diode individually.\
The setting are `disable` (off), `enable` (on) or `auto`; `auto` leaves the control of the diodes to the hardware, like
blinking during data transfer and so on.

`rainbow`'s `brightness` subcommand uses numbers from 0 to 8, or from 0 to 255 if using the `-p` switch for higher
precision.

### Automatic overnight dimming

Automatically adjust the intensity of LEDs using a cronjob to be able to see the state of individual devices during the
day, but not to be dazzled by the diodes in the night.

Create the cron file in the `/etc/cron.d` directory:

```sh
$ cat '/etc/cron.d/rainbow_night'
# Set the light intensity to the second lowest degree every day at 11 PM and set
# it back to maximum every day at 7 AM.
MAILTO=""   # avoid automatic logging of the output
0  23  *  *  *  root   rainbow brightness -p 3
0   7  *  *  *  root   rainbow brightness 5
```

## Hardware upgrades

Most compatible upgrades are available on [Discomp].

[Supported SFP modules].

| Type                 | Product                                      |
| -------------------- | -------------------------------------------- |
| mSATA expansion disk | [Kingston 1024G SSD KC600 SATA3 mSATA]       |
| SFP module           | [Turris RTROM01-RTSF-10G SFP+ copper module] |
| WiFi                 | [Turris Omnia WiFi 6 upgrade kit]            |

## Further readings

- [Turris OS]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[supported sfp modules]: https://wiki.turris.cz/doc/en/public/sfp

<!-- Knowledge base -->
[turris os]: turris%20os.md

<!-- Others -->
[discomp]: https://www.discomp.cz/
[kingston 1024g ssd kc600 sata3 msata]: https://www.amazon.com/gp/product/B08ZNRTDD8/
[turris omnia wifi 6 upgrade kit]: https://www.discomp.cz/turris-omnia-wi-fi-6-upgrade-kit_d120048.html
[turris rtrom01-rtsf-10g sfp+ copper module]: https://www.discomp.cz/turris-rtrom01-rtsf-10g-sfp-metalicky-modul-10-gbps-rj45_d113354.html
