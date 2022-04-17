#!/usr/bin/env sh

export \
	DEBIAN_FRONTEND='noninteractive' \
	LC_ALL='C'

sudo apt update && sudo apt --assume-yes install ansible ansible-lint
