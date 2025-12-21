# Cron

The `cron` command is a runner for something that needs to happen on a schedule.

There are different implementations (Dillon's cron, Vixie's cron, `chrony`, …), and variations of it (e.g., `anacron`,
systemd timers).

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

`cron` searches its spool area (`/var/spool/cron/crontabs` on Linux systems, `/usr/lib/cron/tabs` on Mac OS X) for
crontab files named after accounts in `/etc/passwd`, and loads those it founds into memory.

> [!note]
> Crontabs in the spool directory should **not** be accessed directly.<br/>
> The [`crontab`][crontab] command should be used to access and update them instead.

`cron` also reads `/etc/crontab`, which uses a slightly different format (must provide the username to run the task as
in the task definition).<br/>
Refer `crontab`'s manual page.

On Linux, support for `/etc/cron.d` is included in the cron daemon itself, which handles this location as the
system-wide crontab spool.<br/>
This directory can contain any file defining tasks following the format used in `/etc/crontab`).

Debian uses a default configuration for the cron system that is specific to the distribution.

<details style='padding: 0 0 1rem 1rem'>

Debian uses `/etc/crontab` to run crontabs under `/etc/cron.hourly`, `/etc/cron.daily`, `/etc/cron.weekly` and
`/etc/cron.monthly`.

Additionally, `cron` reads files in `/etc/cron.d`.<br/>
Those are treated in the same way as `/etc/crontab`, and are expected to follow the special format of that file.
However, they are **independent** from `/etc/crontab` and they **do not** inherit environment variable settings from
it.

`/etc/crontab` and the files in `/etc/cron.d` must:

- Be owned by the `root` user.
- **Not** be group- or other-writable.

Files in the above directories are monitored for changes the same way `/etc/crontab` is.<br/>
In contrast to the spool area, those files _can_ also be symlinks, as long as **both** the symlink **and** the file it
points to are owned by the `root` user.<br/>
Files under `/etc/cron.d` do **not** need to be executable, but files under `/etc/cron.{hourly,daily,weekly,monthly}`
do, as they are run by `run-parts`. Refer `run-parts`' manual page.

Files have to pass some sanity checks, including:

- Be **executable**.
- Be owned by the `root` user.
- **Not** be writable by group or other.
- Be named conforming to the filename requirements of `run-parts` (must match `^[a-zA-Z0-9\_\-]$`).<br/>
  Any file which name does **not** conform to these requirements will **not** be executed by `run-parts`.

</details>

The `cron` system wakes up every minute, examines all stored crontabs, and checks each command to see if it should be
executed in the current minute.

When executing commands, any output is mailed _to_ the owner of the crontab (or to the user named in the `MAILTO`
environment variable in the crontab, if such exists) _from_ the  owner  of  the crontab (or from the email address
given in the `MAILFROM` environment variable in the crontab, if such exists).

> [!note]
> Children copies of `cron` running processes have their name coerced to uppercase.<br/>
> Those will be visible in the output of the `syslog` and `ps` commands.

Additionally, `cron` checks every minute if its spool directory's modtime (or the modtime for the `/etc/crontab` file)
has changed. In this case, `cron` examines the modtime on all crontabs and reloads those which have changed.<br/>
This _prevents_ `cron` from needing to be restarted whenever a crontab file is modified.

> [!note]
> The `crontab` command updates the modtime of the spool directory whenever it changes any crontab in it.

Clock changes of more than 3 hours are considered to be corrections to the clock, and the new time is used
immediately.<br/>
When the system clock is changed by less than 3 hours (e.g., at the beginning and end of daylight savings time), jobs
will be executed accordingly:

- If the time moved forwards, jobs which would have run in the time that was skipped will be run soon after the time
change.
- if the time moved backwards by less than 3 hours, jobs _that fall into the repeated time_ will **not** be run again.

Only jobs running at a particular time (not specified as `@hourly`, nor with `*` in the hour or minute specifier) are
affected by time changes.<br/>
Jobs specified with wildcards are run based on the new time immediately.

`cron` logs its action to the `cron` syslog facility. Logging can be checked using the standard `syslogd` facility.

Modern cron implementations have added the `@hourly`, `@daily`, `@weekly`, `@monthly`, and `@yearly` or `@annually`
shorthands for common schedules.

```sh
apt install 'cron'

systemctl --enable --now 'crond.service'
journalctl -xefu 'crond.service'

# Validate crontab files.
crontab -T '/etc/cron.d/prometheus-backup'

# List files in given directories.
# Kinda… useless?
run-parts --list '/etc/cron.daily'

# Print the names of the scripts which would be invoked.
# '--report' is *not* available everywhere.
run-parts --report --test '/etc/cron.hourly'

# Manually run crontab files in given directories.
run-parts '/etc/cron.weekly'

# Check scripts run.
grep 'CRON' '/var/log/syslog'
```

## Further readings

- [Crontab]

### Sources

- [Function of /etc/cron.hourly]
- [Use anacron for a better crontab]
- [Linux tips for using cron to schedule tasks]
- [`/var/spool`: Application spool data][/var/spool: application spool data]
- [Cron Jobs: The Complete Guide]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[crontab]: crontab.md

<!-- Others -->
[/var/spool: Application spool data]: https://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch05s14.html
[Cron Jobs: The Complete Guide]: https://cronitor.io/guides/cron-jobs
[function of /etc/cron.hourly]: https://askubuntu.com/questions/7676/function-of-etc-cron-hourly#607974
[Linux tips for using cron to schedule tasks]: https://opensource.com/article/21/11/cron-linux
[use anacron for a better crontab]: https://opensource.com/article/21/2/linux-automation
