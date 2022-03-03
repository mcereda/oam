#!/usr/bin/env sh

sudo zypper --non-interactive search --installed-only 'python??' \
| sed -e '1,/---/ d' -e 's/ | /,/g' \
| awk -F ',' '{print $2 "-pre-commit"}' \
| xargs sudo zypper install --no-confirm git-lfs
