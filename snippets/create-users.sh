#!/usr/bin/env sh

useradd --create-home --password 'encrypted-password' --shell '/bin/bash' 'username'
useradd -m -p 'encrypted-password' -s '/bin/bash' 'username'

# Non-interactive.
# Skip finger information.
adduser --disabled-password --gecos '' --shell '/bin/sh' 'username'
