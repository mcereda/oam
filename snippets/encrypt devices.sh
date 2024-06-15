#!/usr/bin/env sh

sudo cryptsetup luksFormat '/dev/sdb'
sudo cryptsetup luksOpen '/dev/sdb' '1tb_disk'
sudo mkfs.btrfs --label '1tb_disk' '/dev/mapper/1tb_disk'
sudo mount --types btrfs --options compress-force=zstd:0 '/dev/mapper/1tb_disk' '/mnt/1tb_disk'
sudo umount '/mnt/1tb_disk'
