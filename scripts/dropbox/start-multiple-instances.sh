#!/usr/bin/env sh

DROPBOX_ACCOUNTS="${DROPBOX_ACCOUNTS:-private work}"

for ACCOUNT in $DROPBOX_ACCOUNTS
do
	HOME="${HOME}/.dropbox-${ACCOUNT}" dropbox start &
done
