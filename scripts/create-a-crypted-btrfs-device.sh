#!/usr/bin/env sh

: ${DEVICE:?not set}
: ${LABEL:?not set}
: ${MOUNT_OPTIONS:-compress-force=zstd}

[[ ${EUID} -eq 0 ]]  || (echo "Please rerun this script with root privileges" && exit 1)
[[ -f "${DEVICE}" ]] || echo "${DEVICE} not found"

cryptsetup luksFormat "${DEVICE}"
cryptsetup luksOpen "${DEVICE}" "${LABEL}"
mkfs.btrfs --label "${LABEL}" "/dev/mapper/${LABEL}"
mount --types btrfs --options "${MOUNT_OPTIONS}" "/dev/mapper/${LABEL}" "/mnt/${LABEL}"
umount "/mnt/${LABEL}"
cryptsetup luksClose "${DEVICE}"
