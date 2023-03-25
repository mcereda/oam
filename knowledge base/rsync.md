# rsync

1. [TL;DR](#tldr)
1. [Explored options](#explored-options)
1. [Sources](#sources)

## TL;DR

```sh
# Synchronize 2 files.
rsync 'source/file' 'destination/file'
rsync 'source/file' 'username@host:/destination/file'

# Synchronize the content of 2 or more directories.
rsync -r 'source/dir/' 'destination/dir/'
rsync -r 'source/dir/1/' 'source/dir/n/' 'destination/dir/'

# Synchronize directories **and** their contents to a destination.
rsync -r 'source/dir/1' 'source/dir/n' 'destination/dir'

# Delete files at the destination that to not exist at the source.
rsync … --delete

# Just show what would change at the destination.
rsync -vv … --dry-run

# Copy targets in archive mode if they don't already exist.
rsync -av --ignore-existing 'source/file' 'destination/file'
rsync -av --ignore-existing 'source/dir/1' 'source/dir/n/' 'destination/dir/'

# Exclude files from the sync.
rsync … --exclude "*.DS_Store" --exclude "._*"
rsync … --exclude={"*.DS_Store","._*"}
rsync … --filter "merge filter.txt"

# Delete files from the source after they have been transferred.
rsync … --remove-source-files

# Copy local files to a folder in the user's remote home over SSH on port 1234.
# Compress the data during transfer.
rsync 'source/file' 'username@host:destination/file' -ze 'ssh -p 1234'

# Copy a remote directory to the local host.
# Show total progress and be more verbose.
rsync -avv --info='progress2' 'username@host:/source/dir/' 'destination/dir/'

# Backup items changing at the destination.
rsync … -b --suffix=".backup_$(date +'%F')"
rsync … -b --backup-dir="changes_$(date +'%F')"

# Resume a sync.
rsync … --partial --append
rsync … -P --append-verify

# Limit the transfer's bandwidth.
rsync … --bwlimit='1200'
rsync … --bwlimit='5m'

# Execute multiple syncs to a single destination.
ls -1 'source/dir' \
| xargs -I{} -P $(nproc) -t \
    rsync -a --info='progress2' --dry-run \
      source/dir/{}/ 'username@host:/destination/dir/'
find 'source/dir' -maxdepth 1 -mindepth 1 -type d \
| xargs -I{} -P $(nproc) -t \
    rsync -AXahvz --chown='user' \
      --partial --append-verify \
      --info='progress2' --no-i-r --no-motd \
      {}/ 'username@host:/destination/dir/'

# Sync a directory from/to a Synology NAS.
rsync -AHPXazv --append-verify --no-motd 'source/dir/' 'synology.lan:/shared/folder/' --dry-run
rsync -AHPXazv --append-verify --no-motd --rsh ssh --exclude "#*" --exclude "@*" 'user@synology.lan:/shared/folder/' 'destination/dir/' --delete --dry-run
rsync -AHPazv --append-verify --no-motd --exclude "#*" --exclude "@*" 'source/dir/' 'user@synology.lan:/shared/folder/' --delete --dry-run
rsync -AXaz --append-verify --chown='user' --fake-super --info='progress2' --no-i-r --no-motd --partial -e "ssh -i /home/user/.ssh/id_ed25519 -o UserKnownHostsFile=/home/user/.ssh/known_hosts" 'source/dir/' 'user@synology.lan:/shared/folder/' -n

# Parallel sync.
# Each thread must use a different directory.
parallel -q \
  rsync "path/to/source/dir/{}" "nas.lan:/path/to/destination/dir/" … \
  ::: $( ls -1 path/to/source/dir )
```

## Explored options

| Long format             | Short format | Description                                                                                  |
| ----------------------- | ------------ | -------------------------------------------------------------------------------------------- |
|                         | `-P`         | same as `--partial --progress`                                                               |
| `--acls`                | `-A`         | preserve ACLs; implies `--perms`                                                             |
| `--append-verify`       |              | like `--append`, but use the data already there to check the items                           |
| `--archive`             | `-a`         | archive mode, equals `-rlptgoD`; does **not** imply `-H`, `-A`, nor `-X`                     |
| `--backup-dir=DIR`      |              | use the specified directory to backup changing items                                         |
| `--backup`              | `-b`         | backup items changing at the destination; see also `--suffix` and `--backup-dir`             |
| `--bwlimit=RATE`        |              | limit the socket's I/O bandwidth to _RATE_; with no suffix, the value will be in KBPS        |
| `--checksum`            | `-c`         | skip files basing on checksum instead of modify time and size                                |
| `--chown=USER:GROUP`    |              | simple username/groupname mapping                                                            |
| `--compress`            | `-z`         | compress file data during the transfer                                                       |
| `--crtimes`             |              | **only available on Mac OS X**                                                               |
| `--delete-during`       | `--del`      | set the **receiver** to delete files during the transfer                                     |
| `--delete`              |              | delete items **at the destination** that **don't** exist in the source                       |
| `--dry-run`             | `-n`         | perform a trial run with no changes made                                                     |
| `--exclude=PATTERN`     |              | exclude files matching _PATTERN_                                                             |
| `--executability`       | `-E`         | preserve executability                                                                       |
| `--fake-super`          |              | store/recover privileged attrs using xattrs                                                  |
| `--filter=RULE`         | `-f`         | add a file-filtering _RULE_                                                                  |
| `--hard-links`          | `-H`         | preserve hard links                                                                          |
| `--human-readable`      | `-h`         | output numbers in a human-readable format                                                    |
| `--ignore-existing`     |              | skip updating files that already exist at the destination                                    |
| `--info=FLAGS`          |              | fine-grained informational verbosity; the `progress2` value is available since version 3.1.0 |
| `--links`               | `-l`         | copy symlinks as symlinks                                                                    |
| `--no-inc-recursive`    | `--no-i-r`   | scan all directories on startup instead of incrementally                                     |
| `--no-motd`             |              | suppress daemon-mode MOTD                                                                    |
| `--no-OPTION`           |              | turn off an **implied** OPTION (e.g. `--no-D`)                                               |
| `--partial`             |              | keep partially transferred files                                                             |
| `--progress`            |              | show progress for each file during transfer                                                  |
| `--protect-args`        | `-s`         | no space-splitting; wildcard chars only                                                      |
| `--prune-empty-dirs`    | `-m`         | prune empty directory chains from file-list                                                  |
| `--recursive`           | `-r`         | recurse into directories                                                                     |
| `--remove-source-files` |              | set the **sender** to remove synchronized files; it does **not** remove directories          |
| `--rsh=COMMAND`         | `-e`         | specify the remote shell to use (with options, e.g. _ssh -p 1234_)                           |
| `--sparse`              | `-S`         | turn sequences of nulls into sparse blocks                                                   |
| `--stats`               |              | give some file-transfer stats                                                                |
| `--suffix=SUFFIX`       |              | suffix for backups; defaults to `~`                                                          |
| `--update`              | `-u`         | skip files that are newer on the receiver                                                    |
| `--verbose`             | `-v`         | increase verbosity once for each copy of this switch                                         |
| `--xattrs`              | `-X`         | preserve extended attributes                                                                 |

## Sources

- [cheat.sh]
- [Showing total progress in rsync: is it possible?]

<!-- -->
[cheat.sh]: https://cheat.sh/rsync

<!-- -->
[showing total progress in rsync: is it possible?]: https://serverfault.com/questions/219013/showing-total-progress-in-rsync-is-it-possible#441724
