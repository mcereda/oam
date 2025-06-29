# PowerTOP

> TODO

Linux tool used to diagnose issues with power consumption and power management.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Has an interactive mode one can use to experiment with various power management settings.

When running on battery, PowerTOP tracks power consumption and activity on the system.\
Once there are sufficient measurements, it can start to report power estimates for various activities.

Calibration entails cycling through various display brightness levels (including "off"), USB device activities, and
other workloads.

<details>
  <summary>Setup</summary>

```sh
zypper install 'powertop'
```

</details>

<details>
  <summary>Usage</summary>

```sh
sudo powertop

# Set all tunable options to their `GOOD` setting.
sudo powertop --auto-tune

# Help increasing the accuracy of the consumption measurements estimation.
sudo powertop --calibrate
```

</details>

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
[codebase]: https://github.com/fenrus75/powertop
[documentation]: https://website/docs/
[website]: http://www.01.org/powertop

<!-- Others -->
