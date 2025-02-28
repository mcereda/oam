#!/usr/bin/env fish

# Install
apt install 'apache2-utils'
dnf install 'httpd-tools'

ab -n '750' -c '1' 'http://grafana.example.org/'
ab -t 100 -c 250 -C 'GITLAB_TOKEN=0123…' 'https://gitlab.example.org/'

parallel ab -t 40 -c 100 -C 'GITLAB_TOKEN=1234…' {} ::: https://gitlab.{production,staging}.example.org/
