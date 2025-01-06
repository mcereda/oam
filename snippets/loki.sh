#!/usr/bin/env sh

# Check the server is working
curl 'http://loki.fqdn:3100/ready'
curl 'http://loki.fqdn:3100/metrics'
