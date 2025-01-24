# ClamAV

1. [TL;DR](#tldr)
1. [Gotchas](#gotchas)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Usage</summary>

```sh
# Manually update the virus definitions.
# Do this once **before** starting a scan or the daemon.
# The definitions updater daemon **must be stopped** to avoid its complaints.
sudo systemctl stop 'clamav-freshclam' \
&& sudo 'freshclam' \
&& sudo systemctl enable --now 'clamav-freshclam'

# Scan specific files or directories.
clamscan 'path/to/file'
clamscan --recursive 'path/to/dir'

# Only scan files in a list.
clamscan -i -f '/tmp/scan.list'

# Only return specific results.
clamscan --infected '/home/'
clamscan --suppress-ok-results 'Downloads/'

# Save results to files.
clamscan --bell -i -r '/home' -l 'output.txt'

# Delete infected files.
clamscan -r --remove '/home/user'
clamscan -r -i --move='/home/user/infected' '/home/'

# Limit CPU usage.
nice -n 15 clamscan \
&& clamscan --bell -i -r '/home'

# Use multiple threads.
find . -type f -printf "'%p' " | xargs -P "$(nproc)" -n 1 clamscan
find . -type f | parallel --group --jobs 0 -d '\n' clamscan {}
```

</details>

## Gotchas

- The `--fdpass` option of `clamdscan` (**with** the _d_ in the command name) sends a file descriptor to `clamd` rather
  than a path name, avoiding the need for the `clamav` user to be able to read everyone's files.
- `clamscan` is designed to be **single**-threaded, so it willfully uses a **single** CPU thread when scanning files or
  directories from the command line.<br/>
  Use `xargs` or another executor to run scans in parallel:

  ```sh
  find . -type f -printf "'%p' " | xargs -P $(nproc) -n 1 clamscan
  find . -type f | parallel --group --jobs 0 -d '\n' clamscan {}
  ```

## Further readings

- [Website]
- [Codebase]
- [Documentation]
- [Gentoo Wiki]

### Sources

- [Install ClamAV on Fedora Linux 35]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/Cisco-Talos/clamav
[documentation]: https://docs.clamav.net/
[website]: https://www.clamav.net/

<!-- Others -->
[gentoo wiki]: https://wiki.gentoo.org/wiki/ClamAV
[install clamav on fedora linux 35]: https://www.linuxcapable.com/how-to-install-clamav-on-fedora-35/
