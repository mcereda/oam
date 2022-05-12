# FreeBSD

## TL;DR

```shell
# Initialize package managers.
portsnap auto
pkg bootstrap
```

## Utilities worth noticing

- `bsdinstall`
- `bsdconfig`

## NTP time sync

```conf
# file /etc/rc.conf
ntpd_enable="YES"
ntpd_sync_on_start="YES"
```

## Sources

- [Ports]
- [NTPdate - not updating to current time]
- [Boinc]
- [sbz's FreeBSD commands cheat-sheet]

[boinc]: https://people.freebsd.org/~pav/boinc.html
[ntpdate - not updating to current time]: https://forums.freebsd.org/threads/ntpdate-not-updating-to-current-time.72847/
[ports]: https://docs.freebsd.org/en/books/handbook/ports/
[sbz's freebsd commands cheat-sheet]: https://github.com/sbz/freebsd-commands
