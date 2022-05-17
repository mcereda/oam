#!/usr/bin/env sh

: ${DEVICE:?not set}
: ${LABEL:?not set}

: "${MOUNT_OPTIONS:=compress-force=zstd}"
: "${MOUNT_POINT:=/mnt/$LABEL}"

[[ $EUID -eq 0 ]]  || (echo "Please rerun this script with root privileges" && exit 1)
[[ -f "$DEVICE" ]] || echo "${DEVICE} not found"

cryptsetup luksFormat "$DEVICE"
cryptsetup open "$DEVICE" "$LABEL"

mkfs.btrfs --label "$LABEL" "/dev/mapper/${LABEL}"
mkdir -p "$MOUNT_POINT"
mount -t btrfs -o "$MOUNT_OPTIONS" "/dev/mapper/${LABEL}" "$MOUNT_POINT"

btrfs subvolume create "$MOUNT_POINT/.snapshots"
btrfs subvolume create "$MOUNT_POINT/data"

chown "$USER":"$USER" "$MOUNT_POINT/data"

umount "/mnt/${LABEL}"
cryptsetup close "$DEVICE"
