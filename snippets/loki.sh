#!/usr/bin/env sh

# Verify configuration files
loki -verify-config
loki -config.file='/etc/loki/local-config.yaml' -verify-config

# List available component targets
loki -list-targets
docker run 'docker.io/grafana/loki' -config.file='/etc/loki/local-config.yaml' -list-targets

# Start server components
loki
loki -target='all'
loki -config.file='/etc/loki/config.yaml' -target='read'

# Run on EKS in microservices mode
helm repo add 'grafana' 'https://grafana.github.io/helm-charts' --force-update
helm search repo --versions 'grafana/loki-distributed'
docker pull '012345678901.dkr.ecr.eu-west-1.amazonaws.com/grafana/loki:2.9.10'
helm --namespace 'loki' diff upgrade --install 'loki' \
	--repo 'https://grafana.github.io/helm-charts' 'loki-distributed' --version '0.80.0' \
	--values 'values.yml' --set 'loki.image.registry'='012345678901.dkr.ecr.eu-west-1.amazonaws.com'
helm --namespace 'loki' upgrade --create-namespace --install --cleanup-on-fail 'loki' \
	--repo 'https://grafana.github.io/helm-charts' 'loki-distributed' --version '0.80.0' \
	--values 'values.yml' --set 'loki.image.registry'='012345678901.dkr.ecr.eu-west-1.amazonaws.com' \
	--set 'loki.storageConfig.aws.s3'='s3://eu-west-1' --set 'loki.storageConfig.aws.bucketnames'='loki-data' \
	--set 'loki.storageConfig.boltdb_shipper.shared_store'='s3'

# Print the final configuration to stderr and start
loki -print-config-stderr …

# Check the server is working
curl 'http://loki.fqdn:3100/ready'
curl 'http://loki.fqdn:3100/metrics'
curl 'http://loki.fqdn:3100/services'
