# Lower the power consumption

1. [TL;DR](#tldr)
1. [Disable unused services](#disable-unused-services)
1. [Improve battery performance](#improve-battery-performance)
1. [Tune power-related settings](#tune-power-related-settings)
1. [Further readings](#further-readings)

## TL;DR

1. [Disable unused services].
1. [Tune power-related settings].
1. \[if using a battery] [Improve battery performance].
1. Turn off the NMI watchdog hardlockup detector.\
   The NMI watchdog is a debugging feature to catch hardware hangs that cause a kernel panic. On some systems it can
   generate a lot of interrupts, causing a noticeable increase in power usage.
1. Bump SATA Active Link Power Management to a higher setting.
1. Increase the virtual memory dirty writeback time to help aggregating disk I/O.\
   This reduces spanned disk writes.

```sh
# Summarize performance of the last boot.
sudo systemd-analyze

# Show last boot performance.
# Also shows the process tree.
sudo systemd-analyze critical-chain

# Check power stats.
sudo powertop

# Set all tunable options to their `GOOD` setting.
# Calibration is interactive.
sudo powertop --calibrate && sudo powertop --auto-tune

# Turn off the NMI watchdog hardlockup detector.
echo '0' > '/proc/sys/kernel/nmi_watchdog'

# Bump SATA Active Link Power Management to a higher setting.
echo 'med_power_with_dipm' > '/sys/class/scsi_host/host0/link_power_management_policy'

# Increase the virtual memory dirty writeback time to help aggregating disk I/O.
# Value is in 1/100s of seconds. Default is 500 (5 seconds).
echo 6000 > '/proc/sys/vm/dirty_writeback_centisecs'
sudo sysctl vm.dirty_writeback_centisecs=6000
```

## Disable unused services

```sh
$ sudo systemd-analyze
Startup finished in 13.129s (firmware) + 5.413s (loader) + 1.746s (kernel) + 7.903s (userspace) = 28.192s
graphical.target reached after 1.239s in userspace

$ sudo systemd-analyze critical-chain
The time when unit became active or started is printed after the "@" character.
The time the unit took to start is printed after the "+" character.

graphical.target @1.239s
└─multi-user.target @1.239s
  └─ModemManager.service @1.154s +84ms
    └─polkit.service @937ms +215ms
      └─basic.target @928ms
        └─sockets.target @928ms
          └─dbus.socket @928ms
            └─sysinit.target @924ms
              └─systemd-backlight@backlight:acpi_video0.service @2.273s +8ms
                └─system-systemd\x2dbacklight.slice @2.272s
                  └─system.slice @197ms
                    └─-.slice @197ms
```

## Improve battery performance

```sh
# Enable automatic power management.
# See `tlpui` on GitHub for UI.
sudo systemctl enable --now 'tlp.service'
sudo vim '/etc/tlp.conf'

# Check power stats.
sudo 'powertop'
```

## Tune power-related settings

```sh
sudo powertop --calibrate
sudo powertop --auto-tune
```

## Further readings

- [PowerTOP]
- [Laptop Mode Tools: Extend Your Laptop Battery Life]
- [`laptop-mode-tools` article in the Arch Wiki][arch wiki  laptop-mode-tools]
- [Power management article in the Arch Wiki][arch wiki  power management]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Disable unused services]: #disable-unused-services
[Tune power-related settings]: #tune-power-related-settings
[Improve battery performance]: #improve-battery-performance

<!-- Knowledge base -->
[PowerTOP]: ../powertop.md

<!-- Others -->
[Laptop Mode Tools: Extend Your Laptop Battery Life]: https://www.unixmen.com/laptop-mode-tools-extend-laptop-battery-life/
[arch wiki  laptop-mode-tools]: https://wiki.archlinux.org/title/Laptop_Mode_Tools
[arch wiki  power management]: https://wiki.archlinux.org/title/Power_management
