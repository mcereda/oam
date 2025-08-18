#!/usr/bin/env fish

###
# Pools
# --------------------------------------
###

# List available pools
zpool list

# Show pools' I/O statistics
zpool iostat

# Show pools' configuration and status
zpool status

# List all pools available for import
zpool import

# Import pools
zpool import -a
zpool import -d
zpool import 'vault'
zpool import 'tank' -N
zpool import 'encrypted_pool_name' -l

# Get pools' properties
zpool get all 'vault'

# Set pools' properties
zpool set 'compression=lz4' 'tank'

# Get info about pools' features
man zpool-features

# Show the history of all pool's operations
zpool history 'tank'

# Check pools for errors
# Very cpu *and* disk intensive
zpool scrub 'tank'

# Export pools
# Unmounts *all* filesystems in any given pool
zpool export 'vault'
zpool export -f 'vault'

# Destroy pools
zpool destroy 'tank'

# Restore destroyed pools
# Pools can only be reimported right after the destroy command has been issued
zpool import -D

# Check pool configuration
zdb -C 'vault'

# Display the predicted effect of enabling deduplication
zdb -S 'rpool'

###
# File Systems
# --------------------------------------
# data set = file system
###

# List available datasets
zfs list

# Automatically mount filesystems
# Find a dataset's mountpoint's root path via `zfs get mountpoint 'pool_name'`
zfs mount -alv

# Automatically unmount datasets
zfs unmount 'tank/media'

# Create filesystems
zfs create 'tank/docs'
zfs create -V '1gb' 'vault/good_memories'

# List snapshots
zfs list -t 'all'
zfs list -t 'snapshot,volume,bookmark'

# Create snapshots
zfs snapshot 'vault/good_memories@2024-12-31'

# Check key parameters are fine
zfs get -r checksum,compression,readonly,canmount 'tank'
