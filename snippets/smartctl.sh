#!/usr/bin/env sh

# start tests
sudo smartctl -t 'long' '/dev/sda'
sudo smartctl --type 'short' '/dev/nvme0'

# show devices' SMART health status
sudo smartctl -H '/dev/sda'
sudo smartctl --health '/dev/nvme0'

# print self-tests' results
sudo smartctl -l 'selftest' '/dev/nvme0'

# print results for self-tests and attribute errors
smartctl --attributes --log='selftest' --quietmode='errorsonly' '/dev/sda'
