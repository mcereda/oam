#!/usr/bin/env fish

###
# File Systems
# --------------------------------------
# data set = file system
###

# List available datasets
zfs list

# List snapshots
zfs list -t 'all'
zfs list -t 'snapshot,volume,bookmark'
