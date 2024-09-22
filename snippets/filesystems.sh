#!/usr/bin/env sh

# Get the *sector* size of partitions in 512-byte sectors
sudo blockdev --getsz '/dev/nvme0n1p1'

# Get the *block* size of partitions
sudo blockdev --getbsz '/dev/nvme0n1p1'
