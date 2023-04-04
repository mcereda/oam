# Turris Omnia

## Table of contents <!-- omit in toc -->

1. [Factory reset](#factory-reset)
1. [Hardware upgrades](#hardware-upgrades)
1. [Further readings](#further-readings)
1. [Sources](#sources)

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

## Further readings

- [Turris OS]

## Sources

All the references in the [further readings] section, plus the following:

<!-- project's references -->
[supported sfp modules]: https://wiki.turris.cz/doc/en/public/sfp

<!-- internal references -->
[further readings]: #further-readings
[turris os]: turris%20os.md

<!-- external references -->
[discomp]: https://www.discomp.cz/
[kingston 1024g ssd kc600 sata3 msata]: https://www.amazon.com/gp/product/B08ZNRTDD8/
[turris omnia wifi 6 upgrade kit]: https://www.discomp.cz/turris-omnia-wi-fi-6-upgrade-kit_d120048.html
[turris rtrom01-rtsf-10g sfp+ copper module]: https://www.discomp.cz/turris-rtrom01-rtsf-10g-sfp-metalicky-modul-10-gbps-rj45_d113354.html
