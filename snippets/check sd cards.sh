#!/usr/bin/env sh

# Test drives
# Destroys stored data
sudo f3probe --destructive --time-ops '/dev/sdb'
docker run -it --rm --device '/dev/sdb' 'peron/f3' f3probe --destructive --time-ops '/dev/sdb'
