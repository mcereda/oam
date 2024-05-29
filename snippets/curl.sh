#!/usr/bin/env sh


# Forcefully resolve a host to a given address.
curl 'https://gitlab.mine.info' --resolve 'gitlab.mine.info:443:192.168.32.76'
