#!/usr/bin/env sh

# Add system users
useradd --system --comment '-' --home-dir '/' --user-group 'loki' --shell '/sbin/nologin'
useradd -r -c '-' -d '/' -U 'loki' -s '/sbin/nologin'
