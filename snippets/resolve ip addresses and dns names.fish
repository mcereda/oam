#!/usr/bin/env fish

nslookup 'www.google.com'
nslookup 'grafana.dev.ecs.internal' '172.31.0.2'
nslookup '172.16.43.212' '172.31.0.2'

host 'pi.hole'
host -t 'A' 'ifconfig.me'
host -a '172.16.43.212' '172.31.0.2'

dig 'google.com'
dig 'google.com' 'A'
dig -x '172.217.14.238'
dig '@8.8.8.8' 'google.com'
dig 'google.com' '+short'

resolvectl query 'archlinux.org'

dscacheutil -q 'host' -a 'name' '192.168.1.35'
dscacheutil -q 'host' -a 'name' 'gitlab.lan'
