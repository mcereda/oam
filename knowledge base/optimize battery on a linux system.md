# Optimize battery on a linux system

1. [TL;DR](#tldr)
2. [Disable unused services](#disable-unused-services)
3. [Improve battery performance](#improve-battery-performance)
4. [Further readings](#further-readings)

## TL;DR

```sh
# Summarize performance of the last boot.
sudo systemd-analyze

# Show last boot performance.
# Also shows the process tree.
sudo systemd-analyze critical-chain

# Check power stats.
sudo 'powertop'
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

## Further readings

- [laptop-mode-tools]
- [laptop-mode-tools in the Arch Wiki]

[laptop-mode-tools]: https://www.unixmen.com/laptop-mode-tools-extend-laptop-battery-life/
[laptop-mode-tools in the arch wiki]: https://wiki.archlinux.org/title/Laptop_Mode_Tools
