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

# Use temporary, size-limited volumes in macOS
# The example uses a 2GB RAM disk
hdiutil attach -nomount 'ram://4194304' | xargs diskutil erasevolume HFS+ 'ramdisk' \
&& docker run --rm --name 'alpine' -v "/Volumes/ramdisk/:/ramdisk" -it 'alpine' sh

# List containers with specific metadata values
docker ps -f 'name=pihole' -f 'status=running' -f 'health=healthy' -q

# Remove containers
docker ps -aq | xargs docker container rm

# Build images
docker build -t 'someTag' '.'
docker buildx build -t 'someTag' '.'
docker buildx build '.' -t 'someTag' --platform 'linux/amd64' --progress=plain --no-cache

# Remove build cache and leftovers
docker buildx prune
docker buildx prune -a

# Cleanup
docker image prune -a
docker system prune -a

# Display a summary of the vulnerabilities in images
docker scout qv
docker scout quickview 'debian:unstable-slim'

# Display vulnerabilities in images
docker scout cves
docker scout cves 'alpine'
docker scout cves --format 'only-packages' --only-package-type 'golang' --only-vuln-packages 'fs://.'

# Display base image update recommendations
docker scout recommendations 'golang:1.19.4'

# Check logs
docker compose logs
docker compose --file 'prod.docker-compose.yml' logs --since '30m' --follow 'some-service'

###
# Model runner
################

# Enable in Docker Desktop.
docker desktop enable model-runner
docker desktop enable model-runner --tcp='12434'  # enable TCP interaction from host processes

# Install as plugin.
apt install 'docker-model-plugin'
dnf install 'docker-model-plugin'
pacman -S 'docker-model-plugin'

# Verify the installation.
docker model --help
docker model status

# Install runners.
docker model install-runner
docker model install-runner --backend 'vllm' --gpu 'cuda' --do-not-track

# Stop the current runner.
docker model stop-runner

# Reinstall runners with CUDA GPU support.
docker model reinstall-runner --gpu 'cuda'

# Check the Model Runner container can access the GPU.
docker exec docker-model-runner nvidia-smi

# Disable in Docker Desktop.
docker desktop disable model-runner

# Search for model variants
docker search ai/llama2

# Pull models
docker model pull 'ai/qwen2.5'
docker model pull 'ai/qwen3-coder:30B'
docker model pull 'ai/smollm2:360M-Q4_K_M' 'ai/llama2:7b-q4'
docker model pull 'some.registry.com/models/mistral:latest'

# Run models
docker model run 'ai/smollm2:360M-Q4_K_M' 'Give me a fact about whales'
docker model run -d 'ai/qwen3-coder:30B'
docker model run -e 'MODEL_API_KEY=my-secret-key' --gpus 'all' …
docker model run --gpus '0' --gpu-memory '8g' -e 'MODEL_GPU_LAYERS=40' …
docker model run --gpus '0,1,2' --memory '16g' --memory-swap '16g' …
docker model run --no-gpu --cpus '4' …
docker model run -p '3000:8080' …
docker model run -p '127.0.0.1:8080:8080' …
docker model run -p '8080:8080' -p '9090:9090' …

# Package models
docker model package --gguf "$(pwd)/model.gguf" 'myorg/my-model:v1'  # also imports downloaded GGUF models
docker model package --gguf "$(pwd)/model.gguf" --push 'registry.example.com/ai/custom-llm:v1'

# Import downloaded GGUF models from ollama
# `docker model package` relies on the file extension to detect the format; use a link with the extension in the name
jq -r '.layers|sort_by(.size)[-1].digest|sub(":";"-")' \
	"$HOME/.ollama/models/manifests/registry.ollama.ai/library/lfm2/24b" \
| xargs -I '%%' ln -s "$HOME/.ollama/models/blobs/%%" "/tmp/lfm2-24b.gguf" \
&& docker model package --gguf '/tmp/lfm2-24b.gguf' 'lfm/lfm2:24b'

# Use speculative decoding
docker model configure --speculative-draft-model='lfm/lfm2.5:1.2b' 'lfm/lfm2:24b' \
&& docker model run 'lfm/lfm2:24b' "Hello, tell me about yourself"

# Stop using speculative decoding
docker model configure --speculative-draft-model='' 'lfm/lfm2:24b'

# List downloaded models.
docker model list
docker model ls --json
docker model ls --openai
docker model ls -q

# List running models.
docker model ps

# View models' logs.
docker model logs
docker model logs llm | grep -i gpu
docker model logs -f llm
docker model logs --tail 100 -t llm

# Distribute models across GPUs.
docker model run --gpus 'all' --tensor-parallel '2' 'ai/llama2-70b'

# Show models' configuration.
docker model inspect 'ai/qwen2.5-coder'

# View models' layers.
docker model history 'ai/llama2'

# Configure models.
docker model configure --context-size '8192' 'ai/qwen2.5-coder'

# Reset model configuration.
docker model configure --context-size '-1' 'ai/qwen2.5-coder'

# Remove models.
docker model rm 'ai/llama2'
docker model rm -f 'ai/llama2'
docker model rm $(docker model ls -q)

# Print disk usage.
docker model df

# Full cleanup (remove all models)
docker model purge
