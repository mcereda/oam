# Flipper Zero

Portable fully open-source and customizable multi-tool for pentesters and geeks in a toy-like body.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

| Effect        | Hotkey                                                                                                                 | Notes                    |
| ------------- | ---------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| Power on      | Press and hold `BACK` for 3 seconds                                                                                    |                          |
| Reboot        | Press and hold `LEFT` and `BACK` for 5 seconds                                                                         |                          |
| Hard reboot   | Press and hold `BACK` for 30 seconds                                                                                   | Resets the power circuit |
| Recovery mode | Press and hold `LEFT` and `BACK` for 5 seconds<br/>Release `BACK` and keep holding `LEFT` until the blue LED lights up |                          |

The device will **not** be able to work properly without a microSD card.<br/>
The card of up to 256 GB is needed to store any data (e.g. keys, cards, remotes, databases). A 4 GB one should be
sufficient to store all the necessary data.<br/>
The Flipper Zero may take longer to recognize a microSD card with a higher storage capacity.<br/>
The device uses a slow, energy-efficient SPI interface that can read data at almost 600 KiB/s, which is sufficient for
it's tasks.

Update the device via the _Flipper Mobile_ app or _qFlipper_.

<details>
  <summary>Setup</summary>

```sh
curl -o 'qFlipper.AppImage' 'https://update.flipperzero.one/builds/qFlipper/1.3.3/qFlipper-x86_64-1.3.3.AppImage'
sudo './qFlipper.AppImage' rules install
```

</details>

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Website]
- [Codebase]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/flipperdevices
[documentation]: https://docs.flipper.net/
[website]: https://flipperzero.one/

<!-- Others -->
