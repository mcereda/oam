#!/usr/bin/env sh

ip addr

ip link set eth0 down
ip link set eth0 up
