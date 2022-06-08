#!/usr/bin/env sh

[[ -v DEBUG ]] && set -x

: ${DEVICE:?not set}
: ${POOL_NAME:?not set}

: "${DATASET:=data}"
: "${MOUNT_POINT:=/mnt/${POOL_NAME}}"
: "${USERNAME:=root}"
: "${GROUPNAME:=root}"
: "${UNMOUNT_WHEN_DONE:=true}"

[[ $EUID -eq 0 ]]  || (echo "Re-run this script with root privileges" >&2 && exit 1)
[[ -b "$DEVICE" ]] || (echo "${DEVICE} not found" >&2 && exit 1)

zpool create \
	-o feature@encryption=enabled \
	-O mountpoint="$MOUNT_POINT" \
	-O encryption=on -O keyformat=passphrase \
	-O compression=zstd \
	"$POOL_NAME" \
	"$DEVICE"

zfs create "${POOL_NAME}/${DATASET_NAME}"
chown "$USERNAME":"$GROUPNAME" "${MOUNT_POINT}/${DATASET_NAME}"

[[ "$UNMOUNT_WHEN_DONE" ]] && zfs unmount "${POOL_NAME}/${DATASET_NAME}"

[[ -v DEBUG ]] && set +x
