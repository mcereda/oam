#!/usr/bin/env fish

###
# Server
# ------------------
###

# Install
brew install 'nats-server'
choco install 'nats-server'
docker pull 'nats'
go install 'github.com/nats-io/nats-server/v2@latest'
yay 'nats-server'

# Validate the configuration file
nats-server -c '/etc/nats/nats-server.conf' -t
docker run --rm --name 'pg_flo_nats' -v "$PWD/config/nats-server.conf:/etc/nats/nats-server.conf" 'nats' \
	-c '/etc/nats/nats-server.conf' -t

# Get help
docker run --rm --name 'pg_flo_nats' 'nats' --help

# Run
nats-server -V
docker run --name 'nats' -p '4222:4222' -ti 'nats:latest'

# Run as cluster
docker run --name 'nats-0' --network 'nats' -p '4222:4222' -p '8222:8222' \
	'nats' --http_port '8222' --cluster_name 'NATS' --cluster 'nats://0.0.0.0:6222' \
&& docker run --name 'nats-1' --network 'nats' \
	'nats' --cluster_name 'NATS' --cluster 'nats://0.0.0.0:6222' --routes='nats://ruser:T0pS3cr3t@nats:6222' \
&& curl -fs 'http://localhost:8222/routez'

###
# Client
# ------------------
###

# Install
brew install 'nats-io/nats-tools/nats'

# Check connection to the server
nats server check connection --server 'nats://0.0.0.0:4222'
nats server check connection -s 'nats://localhost:4222'

# Start subscribers
nats subscribe '>' -s '0.0.0.0:4222'
nats subscribe -s 'nats://demo.nats.io' '>'

# Publish messages
nats pub 'hello' 'world' -s '0.0.0.0:4222'
