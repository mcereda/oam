#!/usr/bin/env sh

interface="wlan0"

max_retries=3
timeout=1

log_path="$(dirname $0)/$(basename $0).log"
log_prefix="$(date +'%Y-%m-%d %T')"

i=0
until [ $i -eq $max_retries ]; do
	let "i++"
	if nc -Nz -w $timeout www.google.com 443; then
		echo "$log_prefix" "connection is OK" >> $log_path
		break
	else
		echo "$log_prefix" "no connection, resetting interface" >> $log_path
		sudo ifconfig wlan0 down && sudo ifconfig wlan0 up
	fi
done
