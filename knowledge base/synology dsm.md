# Synology DiskStation Manager

## Rsync

Requirements:

1. the rsync service is enabled under _Control Panel > File Services > rsync_
1. the user has the right permissions for the shared folder under either

   - _Control Panel_ > _Shared Folders_ > _Shared Folder_ edit window > _Permissions_, or
   - _Control Panel_ > _User & Group_ > _User_ or _Group_ edit window > _Permissions_

Examples:

```sh
# From a shared folder on a NAS to a local one.
rsync \
  --archive --hard-links \
  --append-verify --partial \
  --progress --verbose \
  --compress --no-motd \
  --exclude "@*" --exclude "#*" \
  "user@nas:/volume1/shared_folder/" \
  "path/to/local/folder/" \
  --delete --dry-run

# Sync all snapshotted data to a folder
find /volume1/@sharesnap/shared_folder \
  -maxdepth 1 -mindepth 1 \
  -type d
| xargs -I {} -n 1 -t \
    rsync \
      -AXahvz --chown=user --info=progress2 \
      --append-verify --partial \
      --no-inc-recursive --no-motd \
      {}/ \
      /volume2/destination/folder/
```

## Snapshots

Use the **Snapshot Replication** package available in the Package Center for better control and automation.

Gotchas:

1. when the _Make snapshot visible_ option in a shared folder's settings in _Snapshot Replication_ is ticked:

   - the `#snapshot` folder is created in the shared folder's root directory
   - the default snapshots directory for that shared folder is mounted on it in **read only** mode:

     > ```plaintext
     > /dev/mapper/cachedev_0 on /volume1/Data/#snapshot type btrfs (ro,nodev,relatime,ssd,synoacl,space_cache=v2,auto_reclaim_space,metadata_ratio=50,block_group_cache_tree,subvolid=266,subvol=/@syno/@sharesnap/Data)
     > ```

## Deduplicate blocks in a volume

Requirements:

1. `docker` needs to be installed from the package manager, as it is simpler to run a container than installing `duperemove` and all its dependencies on the machine
1. the container needs to be run in privileged mode (`--privileged`) due to its actions on the disk

Gotchas:

1. the container might fail on very large datasets, usually due to Out Of Memory (OOM) issues; to avoid this:

   1. offload the hashes from RAM using a hash file (`--hashfile "/volume1/NetBackup/duperemove.tmp"`)
   1. use smaller datasets where possible, like a shared folder and just one of its snapshots instead of all of them

1. `duperemove` can dedupe blocks only if acting on folders in a _rw_ mount; when deduplicating snapshots, use their _rw_ mount path `/@syno/@sharesnap/shared_folder` instead of their _ro_ version `/volumeN/shared_folder/#snapshot`

Examples:

```sh
# small/medium dataset
# 2 folders in a shared folder
sudo docker run --privileged \
  --rm --name duperemove \
  --mount "type=bind,source=/volume1/Data,target=/sharedfolder" \
  michelecereda/duperemove:0.11.2 \
    -Adhr \
    "/sharedfolder/folder1" "/sharedfolder/folder2"

# large dataset
# 1 shared folder and all its snapshots
sudo docker run --privileged \
  --rm --name duperemove \
  --mount "type=bind,source=/volume1,target=/volume1" \
  michelecereda/duperemove:0.11.2 \
    -Adhr \
    --hashfile "/volume1/NetBackup/duperemove.tmp" \
    "/volume1/Data" "/volume1/@sharesnap/Data"
```

## Sources

- [Configuring deduplication block on the Synology]

[configuring deduplication block on the synology]: https://onedrive.live.com/?authkey=%21ACYMJq62iJaU7HY&cid=1E8D74207941B8DD&id=1E8D74207941B8DD%21243&parId=1E8D74207941B8DD%21121&o=OneUp
