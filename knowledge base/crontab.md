# Crontab

## TL;DR

```sh
# List existing jobs.
crontab -l
sudo crontab -l -u other_user

# Edit crontab files.
crontab -e
sudo crontab -e -u other_user

# Replace the current crontab with the contents of a given file.
crontab path/to/file
sudo crontab -u other_user path/to/file

# Remove all cron jobs.
crontab -r
sudo crontab -r -u other_user
```

```text
# Run 'pwd' every day at 10PM.
0 22 * * * pwd

# Run 'ls' every 10 minutes.
*/10 * * * * ls

# Run a script at 02:34 every Friday.
34 2 * * Fri /absolute/path/to/script.sh
```

## Sources

- [cheat.sh]

[cheat.sh]: https://cheat.sh/crontab
