#!/usr/bin/env sh

# Install
apt install 'promtail'
brew install 'promtail'
dnf install 'promtail'
docker run \
	-v "${PWD}/config.yml:/etc/promtail/config.yml" -v '/var/log:/var/log' \
	'grafana/promtail:3.2.1' --config.file='/etc/promtail/config.yml'
helm upgrade --install 'promtail' \
	--repo 'https://grafana.github.io/helm-charts' 'grafana/promtail' \
	--values 'values.yaml'

# Validate config files.
# Seems to be quite useless, it does not find stupid configuration errors.
promtail -check-syntax -config.file '/etc/promtail/config.yml'

# Do a test run
promtail -dry-run -config.file '/etc/promtail/config.yml'

# Check the server is working
curl 'http://promtail.fqdn:9080/ready'
curl 'http://promtail.fqdn:9080/metrics'

# Connect to the web server
open 'http://promtail.fqdn:9080/'
