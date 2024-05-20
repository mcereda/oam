#!/usr/bin/env sh

# Print out 32 random characters.
openssl rand -base64 32
gpg --gen-random --armor 1 32

# Print out 32 random alphanumeric characters.
date '+%s' | sha256sum | base64 | head -c '32'
cat '/dev/urandom' | LC_ALL='C' tr -dc '[:alnum:]' | fold -w '32' | head -n '1'

# XKCD-inspired passwords.
xkcdpass
pipx run 'xkcdpass' -d '-' -C 'random' -n 5
gopass pwgen -x --xc --xl 'en' --xn --xs '.' 3
