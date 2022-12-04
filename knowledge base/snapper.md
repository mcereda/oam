# Snapper

## TL;DR

```sh
# List existing configurations.
snapper list-config

# List existing snapshots.
snapper list

# Create a manual standalone snapshot.
snapper \
  --config root \
  create --read-only \
    --type single \
    --description "manual checkpoint" \
    --userdata "important=yes"

# Rollback to snapshot #0.
snapper rollback 0

# Delete one or more snapshots.
snapper delete 5
snapper delete --sync {7..9}

# Compare 2 snapshots.
snapper status 0..6
snapper diff 6..21

# Change values of an existing snapshot.
# the cleanup algorithm must be one of 'number', 'timeline', 'empty-pre-post' or
# '' (empty string, to cancel).
# Any description must be less than 25 characters.
# Any userdata must contain KEY=VALUE couples.
snapper modify \
  --userdata 'important=yes' \
  --description 'new description' \
  --cleanup-algorithm '' 12
```

## Further readings

- [System recovery and snapshot management with Snapper]
- [Arch Wiki]

<!-- external references -->
[arch wiki]: https://wiki.archlinux.org/title/snapper
[system recovery and snapshot management with snapper]: https://doc.opensuse.org/documentation/leap/archive/15.0/reference/html/book.opensuse.reference/cha.snapper.html
