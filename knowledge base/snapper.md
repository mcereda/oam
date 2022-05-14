# Snapper

## TL;DR

```sh
# list existing configurations
snapper list-config

# list existing snapshots
snapper list

# create a manual standalone snapshot
snapper --config root create --type single --description "manual checkpoint" --userdata "important=yes" --read-only

# rollback to snapshot 0
snapper rollback 0

# delete one or more snapshots
snapper delete 5
snapper delete --sync {7..9}

# compare 2 snapshots
snapper status 0..6
snapper diff 6..21
```

## Further readings

- [Arch Wiki]

[arch wiki]: https://wiki.archlinux.org/title/snapper
