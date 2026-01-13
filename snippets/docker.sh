#!/usr/bin/env sh

docker info
docker info -f 'json'
docker system info --format '{{range .Plugins.Volume}}{{println .}}{{end}}'

docker images -a
docker images --digests

docker volume create 'website'
docker volume inspect -f '{{ .Mountpoint }}' 'website'
sudo vim '/var/lib/docker/volumes/website/_data/index.html'

docker run -d --name 'some-nginx' -v '/some/content:/usr/share/nginx/html:ro' 'nginx'
docker run --rm --name 'redash-db-migrations' --platform 'linux/amd64' --dns '172.31.0.2' \
	--env 'REDASH_COOKIE_SECRET' --env 'REDASH_DATABASE_URL' --env 'REDASH_REDIS_URL' \
	"$REDASH_IMAGE" manage db upgrade
docker run --rm --name 'pulumi' \
	--env 'AWS_DEFAULT_REGION' --env 'AWS_ACCESS_KEY_ID' --env 'AWS_SECRET_ACCESS_KEY' --env 'AWS_PROFILE' \
	--env-file '.env' --env-file '.env.local' \
	-v '${PWD}:/pulumi/projects' -v '${HOME}/.aws:/root/.aws:ro' \
	'pulumi/pulumi-nodejs:3.148.0@sha256:2463ac69ec760635a9320b9aaca4e374a9c220f54a6c8badef35fd47c1da5976' \
	pulumi preview --suppress-outputs --stack 'dev'

docker logs --since '5m' -f 'dblab_server'
docker logs --since '2024-09-07' 'dblab_server'
docker logs --since '2024-09-09T09:05:00' --until '2024-09-09T10:05:00' 'dblab_server'

docker login
docker login -u 'whatever' -p 'glpat-ABC012def345GhI678jKl' 'gitlab.example.org:5050'
aws ecr get-login-password | docker login --username 'AWS' --password-stdin '012345678901.dkr.ecr.eu-west-1.amazonaws.com'

# Get image digests with*out* pulling them
docker buildx imagetools inspect 'pulumi/pulumi-nodejs' --format '{{ json .Manifest.Digest }}'
docker buildx imagetools inspect 'pulumi/pulumi-nodejs' --format '{{ json .Manifest }}' | jq -r '.digest' -

# Send images to remote nodes with Docker
docker save 'local/image:latest' | ssh -C 'user@remote.host' docker load

# Inspect resources
docker inspect 'ghcr.io/jqlang/jq:latest'  # image
docker inspect 'host'  # network
docker inspect 'prometheus-1'  # container

# Install compose directly from package
dnf install 'https://download.docker.com/linux/fedora/41/aarch64/stable/Packages/docker-compose-plugin-2.32.1-1.fc41.aarch64.rpm'

# Create non-standard volumes
docker volume create --driver 'flocker' -o 'size=20GB' 'my-named-volume'
docker volume create --driver 'local' --opt 'type=tmpfs' --opt 'device=tmpfs' --opt 'o=size=100m,uid=1000' 'foo'
docker volume create --driver 'local' --opt 'type=btrfs' --opt 'device=/dev/sda2'
docker volume create --driver 'convoy' --opt 'size=100m' 'test'

# Use temporary, size-limited volumes in Mac OS X
# The example uses a 2GB RAM disk
hdiutil attach -nomount 'ram://4194304' | xargs diskutil erasevolume HFS+ 'ramdisk' \
&& docker run --rm --name 'alpine' -v "/Volumes/ramdisk/:/ramdisk" -it 'alpine' sh

# Remove containers
docker ps -aq | xargs docker container rm

# Build images
docker build -t 'someTag' '.'
docker buildx build -t 'someTag' '.'
docker buildx build '.' -t 'someTag' --platform 'linux/amd64' --progress=plain --no-cache

# Remove build cache and leftovers
docker buildx prune
docker buildx prune -a

# Check logs
docker compose logs
docker compose --file 'prod.docker-compose.yml' logs --since '30m' --follow 'some-service'
