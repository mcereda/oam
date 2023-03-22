#!/usr/bin/env sh

[[ -v DEBUG ]] && set -x

: ${DEVICE:?not set}
: ${LABEL:?not set}

: "${MAPPER_NAME:=${LABEL// /}}"
: "${MOUNT_OPTIONS:=compress-force=zstd}"
: "${MOUNT_POINT:=/mnt/$LABEL}"
: "${USERNAME:=root}"
: "${GROUPNAME:=root}"
: "${CLOSE_WHEN_DONE:=true}"

[[ $EUID -eq 0 ]]  || (echo "Re-run this script with root privileges" >&2 && exit 1)
[[ -b "$DEVICE" ]] || (echo "${DEVICE} not found" >&2 && exit 1)

cryptsetup luksFormat "$DEVICE"
cryptsetup open "$DEVICE" "$MAPPER_NAME"

mkfs.btrfs -f --label "$LABEL" "/dev/mapper/${MAPPER_NAME}"
mkdir -p "$MOUNT_POINT"
mount -t btrfs -o "$MOUNT_OPTIONS" "/dev/mapper/${MAPPER_NAME}" "$MOUNT_POINT"

btrfs subvolume create "$MOUNT_POINT/.snapshots"
btrfs subvolume create "$MOUNT_POINT/data"

chown "$USERNAME":"$GROUPNAME" "$MOUNT_POINT/data"

if [[ "$CLOSE_WHEN_DONE" == false ]]
then
	umount "/mnt/${LABEL}"
	cryptsetup close "/dev/mapper/${MAPPER_NAME}"
fi

[[ -v "$DEBUG" ]] && set +x
