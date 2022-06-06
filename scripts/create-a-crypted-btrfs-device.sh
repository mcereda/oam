#!/usr/bin/env sh

: ${DEVICE:?not set}
: ${LABEL:?not set}

: "${MOUNT_OPTIONS:=compress-force=zstd}"
: "${MOUNT_POINT:=/mnt/$LABEL}"
: "${USERNAME:=root}"
: "${GROUPNAME:=root}"
: "${CLOSE_WHEN_DONE:=true}"

[[ $EUID -eq 0 ]]  || (echo "Re-run this script with root privileges" >&2 && exit 1)
[[ -b "$DEVICE" ]] || (echo "${DEVICE} not found" >&2 && exit 1)

cryptsetup luksFormat "$DEVICE"
cryptsetup open "$DEVICE" "$LABEL"

mkfs.btrfs --label "$LABEL" "/dev/mapper/${LABEL}"
mkdir -p "$MOUNT_POINT"
mount -t btrfs -o "$MOUNT_OPTIONS" "/dev/mapper/${LABEL}" "$MOUNT_POINT"

btrfs subvolume create "$MOUNT_POINT/.snapshots"
btrfs subvolume create "$MOUNT_POINT/data"

chown "$USER":"$USER" "$MOUNT_POINT/data"

if [[ "$CLOSE_WHEN_DONE" ]]
then
	umount "/mnt/${LABEL}"
	cryptsetup close "$DEVICE"
fi
