# Crontab

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# List existing jobs.
crontab -l
sudo crontab -l -u 'jane'

# Edit crontab files.
crontab -e
sudo crontab -e -u 'mark'

# Replace the current crontab with the contents of a given file.
crontab 'path/to/file'
sudo crontab -u 'kelly' 'path/to/file'

# Validate crontab files.
crontab -T '/etc/cron.d/prometheus-backup'

# Remove all cron jobs.
crontab -r
sudo crontab -r -u 'nana'
```

```txt
# Run 'pwd' every day at 10PM.
0 22 * * * pwd

# Run 'ls' every 10 minutes.
*/10 * * * * ls

# Run a script at 02:34 every Friday.
34 2 * * Fri /absolute/path/to/script.sh
```

## Further readings

- [Cron]

### Sources

- [cheat.sh]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[cron]: cron.md

<!-- Others -->
[cheat.sh]: https://cheat.sh/crontab
