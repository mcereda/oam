#!/usr/bin/env fish

# Validate configuration files
logstash -tf 'config.conf'
logstash --config.test_and_exit --path.config 'configDir' --log.level='debug'
ls -1 *'.conf' | xargs -tn1 /usr/share/logstash/bin/logstash --api.enabled='false' --log.level='info' -tf
docker run --rm -ti -v "$PWD:/usr/share/logstash/custom" 'docker.io/library/logstash:7.17.27' \
	--api.enabled='false' --log.level='info' -tf 'custom'

# Force configuration files reload and restart the pipelines
kill -SIGHUP '14175'

# Get Logstash's status
curl -fsS 'localhost:9600/_health_report?pretty'

# Get pipelines statistics
curl -fsS 'localhost:9600/_node/stats/pipelines?pretty'
curl -fsS 'localhost:9600/_node/stats/pipelines/somePipeline?pretty'
curl -fsS 'localhost:9600/_node/stats/pipelines/serviceName' | jq '.pipelines[].plugins.outputs' -
