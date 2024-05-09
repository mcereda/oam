#!/usr/bin/env sh

# Fix permission errors when it keeps answering 502 and this log message appears:
# connect() to unix:/var/opt/gitlab/gitlab-workhorse/sockets/socket failed (13: Permission denied)
docker exec 'gitlab' chown 'gitlab-www:git' '/var/opt/gitlab/gitlab-workhorse/sockets/socket'

# Given by Gitlab itself, but not sure it actually does anything
docker exec 'gitlab' update-permissions

# Health checks
docker exec 'gitlab' curl -fksLS -o '/dev/null' -w "%{http_code}" 'https://localhost/'
nc localhost 22 -e true
