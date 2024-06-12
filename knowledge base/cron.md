# Cron

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Files in `/etc/cron.hourly` and similar must:

- Be **scripts**.<br/>
  Normal crontab files will error out.
- Be **executable**.<br/>
  If not executable, execution will silently fail.
- Match the Debian cron script namespace (`^[a-zA-Z0-9_-]+$`).<br/>
  Files **with** an extension **won't** work.

```sh
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
```

## Further readings

- [Crontab]

### Sources

- [Function of /etc/cron.hourly]
- [Use anacron for a better crontab]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[crontab]: crontab.md

<!-- Others -->
[function of /etc/cron.hourly]: https://askubuntu.com/questions/7676/function-of-etc-cron-hourly#607974
[use anacron for a better crontab]: https://opensource.com/article/21/2/linux-automation
