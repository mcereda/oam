#!/usr/bin/env bash

: "${INTERFACE:='wlan0'}"

: ${MAX_RETRIES:=3}
: ${TIMEOUT:=1}

: "${LOG_PATH=$(dirname $0)/$(basename $0).log}"
: "${LOG_PREFIX=$(date +'%Y-%m-%d %T')}"

i=0
until [ $i -eq $MAX_RETRIES ]; do
	let "i++"
	if nc -Nz -w $TIMEOUT www.google.com 443; then
		echo "$LOG_PREFIX" "connection is OK" >> $LOG_PATH
		break
	else
		echo "$LOG_PREFIX" "no connection, resetting interface" >> $LOG_PATH
		sudo ifconfig $INTERFACE down && sudo ifconfig $INTERFACE up
	fi
done
