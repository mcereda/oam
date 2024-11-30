#!/usr/bin/env sh

docker images -a
docker images --digests

docker volume create 'website'
docker volume inspect -f '{{ .Mountpoint }}' 'website'
sudo vim '/var/lib/docker/volumes/website/_data/index.html'

docker run -d --name 'some-nginx' -v '/some/content:/usr/share/nginx/html:ro' 'nginx'

docker logs --since '5m' -f 'dblab_server'
docker logs --since '2024-09-07' 'dblab_server'
docker logs --since '2024-09-09T09:05:00' --until '2024-09-09T10:05:00' 'dblab_server'

docker login
docker login -u 'whatever' -p 'glpat-ABC012def345GhI678jKl' 'gitlab.example.org:5050'
aws ecr get-login-password | docker login --username 'AWS' --password-stdin '012345678901.dkr.ecr.eu-west-1.amazonaws.com'

# Send images to remote nodes with Docker
docker save 'local/image:latest' | ssh -C 'user@remote.host' docker load

# Inspect resources
docker inspect 'ghcr.io/jqlang/jq:latest'  # image
docker inspect 'host'  # network
docker inspect 'prometheus-1'  # container
