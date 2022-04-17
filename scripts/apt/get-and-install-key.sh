#!/usr/bin/env sh

export \
	DEBIAN_FRONTEND='noninteractive' \
	LC_ALL='C'

if [[ "$APT_KEYS" != "" ]]
then
    sudo apt-key adv --recv-keys $APT_KEYS
fi
