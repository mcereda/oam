# Synology DiskStation Manager

## Table of contents <!-- omit in toc -->

1. [System's shared folders](#systems-shared-folders)
1. [Rsync](#rsync)
1. [Snapshots](#snapshots)
1. [Encrypt data on a USB disk](#encrypt-data-on-a-usb-disk)
1. [Data deduplication](#data-deduplication)
   1. [Remove duplicated files with jdupes](#remove-duplicated-files-with-jdupes)
   1. [Deduplicate blocks in a volume with duperemove](#deduplicate-blocks-in-a-volume-with-duperemove)
1. [Use keybase](#use-keybase)
   1. [Manage git repositories with a containerized keybase instance](#manage-git-repositories-with-a-containerized-keybase-instance)
1. [Ask for a feature to be implemented](#ask-for-a-feature-to-be-implemented)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## System's shared folders

Automatically created by services or packages.

Cannot be changed/removed manually if the package creating them is still active or installed.

```txt
/volume1
├── docker      # data container for the Docker service, created by it upon installation
├── homes       # all users' home directories, created by the SSH service upon activation
├── music       # created by the Media Server package upon installation
├── NetBackup   # created by the rsync service upon activation
├── photo       # created by the Media Server package upon installation
└── video       # created by the Media Server package upon installation
```

USB disks are recognized as shared folders automatically and mounted under `/volumeUSBX`:

```txt
/volumeUSB1
└── whatever
```

## Rsync

Requirements:

1. the rsync service is enabled under _Control Panel > File Services > rsync_
1. the user has the right permissions for the shared folder under either

   - _Control Panel_ > _Shared Folders_ > _Shared Folder_ edit window > _Permissions_, or
   - _Control Panel_ > _User & Group_ > _User_ or _Group_ edit window > _Permissions_

Examples:

```sh
# From a shared folder on a NAS to a local one.
# Use the SSH port defined in the NAS settings.
rsync \
  "user@nas:/volume1/shared_folder/" \
  "path/to/local/folder/" \
  --archive --copy-links --protect-args \
  --acls --xattrs --fake-super \
  --partial --append-verify --sparse \
  --progress -vv --no-inc-recursive \
  --compress --no-motd --rsh='ssh -p12345' \
  --exclude "@eaDir" --exclude "#recycle" \
  --delete --dry-run

# Sync all snapshotted data to a folder.
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

     > ```txt
     > /dev/mapper/cachedev_0 on /volume1/Data/#snapshot type btrfs (ro,nodev,relatime,ssd,synoacl,space_cache=v2,auto_reclaim_space,metadata_ratio=50,block_group_cache_tree,subvolid=266,subvol=/@syno/@sharesnap/Data)
     > ```

## Encrypt data on a USB disk

Synology DNS does not equip utilities like `cryptsetup` or TrueCrypt or such. Also, creating a docker container for it is at this time a little bit too much for me. But, it does include `ecryptfs`.

I found [this solution on Reddit][encrypting an attached external usb drive?] to use the included `ecryptfs`. It has downsides (`ecryptfs`' vulnerabilities, the fact that terminal commands are logged in `/var/log/bash_history.log` and a password would be visible, etc), but hey, that is what is used internally, so...

> Implementation:
>
> 1. Create a shared folder called "crypt" [on your normal Synology Diskstation volume]
> 1. Plug in the USB drive if you haven't already
> 1. Log into DSM manager
> 1. Go to network services, and select terminal
> 1. Enable Telnet service. (If you have been manually changing the firewall, make sure you've unblocked port 23)
> 1. Telnet into the Synology box - logging in as root
> 1. Type this command to create the directory on your USB drive: "mkdir /volumeUSB1/usbshare/@crypt@"
> 1. Update the _blahblahblah_ password below and type into your telnet session (note - it should all be on one line): "mount.ecryptfs /volumeUSB1/usbshare/@crypt@ /volume1/crypt -o \key=passphrase:passphrase_passwd=blahblahblah,ecryptfs_cipher=aes,ecryptfs_key_bytes=32,\ecryptfs_passthrough=n,no_sig_cache,ecryptfs_enable_filename_crypto=y"
> 1. Any data you copy into "crypt" above, will now be encrypted and saved in "usbshare1/@crypt@". To check - create a new folder in the folder "crypt" and have a look at how it appears encrypted when you look into "usbshare1/@crypt@" from DSM manager.
> 1. From here - set up any backup jobs you wish to copy into the "crypt" shared folder you created.
> 1. When you are ready to eject the drive make sure you unmount it first by typing into your telnet session "umount /volumeUSB1/usbshare/@crypt@" and then eject it in the normal way from DSM.
> 1. Disable the telnet service if you are no longer using it

## Data deduplication

Requirements:

1. `docker` needs to be installed from the package manager, as it is simpler (and safer?) to run a container than installing `duperemove` or `jdupes` and all their dependencies on the machine

### Remove duplicated files with jdupes

Examples:

```sh
# `sudo` is only needed if the user has no privileges to run `docker` commands.
sudo docker run \
  -it --init --rm --name jdupes \
  -v "/volume/shared_folder1:/data1" \
  -v "/volume/shared_folder2:/data2" \
  ghcr.io/jbruchon/jdupes:latest \
    -drOZ \
    -X 'nostr:@eaDir' -X 'nostr:#recycle' \
    "/data1" "/data2"
```

### Deduplicate blocks in a volume with duperemove

Gotchas:

1. `duperemove`'s container needs to be run in privileged mode (`--privileged`) due to it taking actions on the disk
1. the container might fail on very large datasets, usually due to Out Of Memory (OOM) issues; to avoid this:
   - offload the hashes from RAM using a hash file (`--hashfile "/volume1/NetBackup/duperemove.tmp"`)
   - use smaller datasets where possible, like a shared folder and just one of its snapshots instead of all of them
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

## Use keybase

Just use a containerized service and execute commands with it:

```sh
# Run the service.
docker run -d --name 'keybase' \
  -e KEYBASE_SERVICE='1' \
  -e KEYBASE_USERNAME='user' \
  -e KEYBASE_PAPERKEY='paper key' \
  'keybaseio/client:stable'

# Execute commands using the containerized service.
docker exec \
  --user 'keybase' \
  keybase \
    keybase whoami
```

### Manage git repositories with a containerized keybase instance

See the [readme for michelecereda/keybaseio-client][michelecereda/keybaseio-client].

## Ask for a feature to be implemented

Use the [online feature request form]. Posting a request on the community site will not work.

## Further readings

- [CLI Administrator Guide for Synology NAS]
- [Making disk hibernation work on Synology DSM 7]

## Sources

All the references in the [further readings] section, plus the following:

- [Configuring deduplication block on the Synology]
- [Encrypting an attached external USB drive?]

<!-- project's references -->

[cli administrator guide for synology nas]: https://global.download.synology.com/download/Document/Software/DeveloperGuide/Firmware/DSM/All/enu/Synology_DiskStation_Administration_CLI_Guide.pdf
[online feature request form]: https://www.synology.com/en-us/form/inquiry/feature

<!-- internal references -->

[further readings]: #further-readings

[michelecereda/keybaseio-client]: ../docker/keybaseio-client/README.md

<!-- external references -->

[configuring deduplication block on the synology]: https://onedrive.live.com/?authkey=%21ACYMJq62iJaU7HY&cid=1E8D74207941B8DD&id=1E8D74207941B8DD%21243&parId=1E8D74207941B8DD%21121&o=OneUp
[encrypting an attached external usb drive?]: https://www.reddit.com/r/synology/comments/jq4aw6/encrypting_an_attached_external_usb_drive/
[making disk hibernation work on synology dsm 7]: https://www.reddit.com/r/synology/comments/10cpbqd/making_disk_hibernation_work_on_synology_dsm_7/
