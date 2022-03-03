#!/usr/bin/env sh

export \
	KEYBASE_USERNAME="${KEYBASE_USERNAME:?not set}" \
	KEYBASE_PAPERKEY="${KEYBASE_PAPERKEY:?not set}"

source install.sh

run_keybase
keybase oneshot
keybase git list
