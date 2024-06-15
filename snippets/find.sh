#!/usr/bin/env sh

# Ignore permission errors.
# -------------------------

find '/' -type 'f' -name 'git-remote-keybase' 2>/dev/null

# GNU find.
find '/' -type 'f' -name 'git-remote-keybase' -readable

find '.' -type 'd' -name '.git' -exec dirname {} ';' | xargs -I {} -n 1 -t git -C {} remote --verbose
