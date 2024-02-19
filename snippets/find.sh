#!/usr/bin/env sh

# Ignore permission errors.
# -------------------------

find '/' -type 'f' -name 'git-remote-keybase' 2>/dev/null

# GNU find.
find '/' -type 'f' -name 'git-remote-keybase' -readable
