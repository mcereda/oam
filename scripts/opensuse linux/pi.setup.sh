#!/usr/bin/env sh

: "${USER_FULL_NAME:='Mek'}"
: "${USER_NAME:='mek'}"
: "${USER_PASSWORD:?'not set'}"
: "${USER_TYPE:='local'}"

yast users add batchmode verbose \
	type="$USER_TYPE" \
	username="$USER_NAME" \
	password="$USER_PASSWORD" \
	cn="$USER_FULL_NAME"
