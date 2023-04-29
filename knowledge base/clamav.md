# ClamAV

## TL;DR

```sh
# Manually update the virus definitions.
# Do this once **before** starting a scan or the daemon.
# The definitions updater daemon **must be stopped** to avoid its complaints.
sudo systemctl stop 'clamav-freshclam' \
&& sudo 'freshclam' \
&& sudo systemctl enable --now 'clamav-freshclam'

# scan a file or directory.
clamscan 'path/to/file'
clamscan --recursive 'path/to/dir'

# only return specific files.
clamscan --infected '/home/'
clamscan --suppress-ok-results 'Downloads/'

# save results to file.
clamscan --bell -i -r '/home' -l 'output.txt'

# scan files in a list.
clamscan -i -f '/tmp/scan.list'

# remove infected files.
clamscan -r --remove '/home/user'
clamscan -r -i --move='/home/user/infected' '/home/'

# limit cpu usage.
nice -n 15 clamscan \
&& clamscan --bell -i -r '/home'

# use multiple threads.
find . -type f -printf "'%p' " | xargs -P "$(nproc)" -n 1 clamscan
find . -type f | parallel --group --jobs 0 -d '\n' clamscan {}
```

## Gotchas

- The `--fdpass` option of `clamdscan` (notice the _d_ in the command) sends a file descriptor to clamd rather than a path name, avoiding the need for the `clamav` user to be able to read everyone's files
- `clamscan` is designed to be single-threaded, so when scanning a file or directory from the command line only a single CPU thread is used; use `xargs` or another executor to run a scan in parallel:

  ```sh
  find . -type f -printf "'%p' " | xargs -P $(nproc) -n 1 clamscan
  find . -type f | parallel --group --jobs 0 -d '\n' clamscan {}
  ```

## Further readings

- [Gentoo Wiki]

[gentoo wiki]: https://wiki.gentoo.org/wiki/ClamAV

## Sources

- [Install ClamAV on Fedora Linux 35]

[install clamav on fedora linux 35]: https://www.linuxcapable.com/how-to-install-clamav-on-fedora-35/
