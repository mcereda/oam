#!/usr/bin/env sh

# Ignore permission errors
find '/' -type 'f' -name 'git-remote-keybase' 2>/dev/null
find '/' -type 'f' -name 'git-remote-keybase' -readable    # GNU find only

# Find files modified in the last 24h
find '.' -newermt '24 hours ago'
find '.' -mtime '-24h'

# Find files changed in the last 24h
find '.' -newerct '24 hours ago'
find '.' -ctime '-24h'

find '.' -type 'd' -name '.git' -exec dirname {} ';' | xargs -t -I {} git -C {} remote --verbose
