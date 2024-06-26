#!/usr/bin/env sh

docker images -a
docker images --digests

docker volume create 'website'
docker volume inspect -f '{{ .Mountpoint }}' 'website'
sudo vim '/var/lib/docker/volumes/website/_data/index.html'

docker run -d --name 'some-nginx' -v '/some/content:/usr/share/nginx/html:ro' 'nginx'

docker logs --since '5m' -f 'dblab_server'
