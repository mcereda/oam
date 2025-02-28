#!/usr/bin/env fish

# Create a 10GB file
dd if='/dev/zero' of='/spaceHogger' count='10485760' bs='1024'
dd if='/dev/zero' of='/spaceHogger' count='10' bs='1G'
bash -c 'dd if="/dev/zero" of="/spaceHogger" count="$(( 1024 * 10 ))" bs="1M" status="progress"'
dd if='/dev/zero' of='/spaceHogger' count=(math 1024 '*' 10) bs='1M'

# Check disk drives contain no bad blocks
dd if='/dev/ada0' of='/dev/null' bs='1m'

# Refresh of disk drives
# Used to prevent presently recoverable read errors from progressing into unrecoverable read errors
dd if='/dev/ada0' of='/dev/ada0' bs='1m' status='progress'

# Write filesystem images to disks
# Pad the end with zeros, if necessary, to a 1MiB boundary
dd if='memstick.img' of='/dev/da0' bs='1m' conv='noerror,sync'


###
# Alternatives
###

fallocate -l '1G' '1g-file'
fallocate -zl '10G' '10g-file-zeroed'
