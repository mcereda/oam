#!/usr/bin/env sh

# Does *not* ask for confirmation
sfdisk --delete '/dev/sda'

wipefs -a '/dev/sda'
