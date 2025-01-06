#!/usr/bin/env sh

# Export all existing dashboards by ID
curl -sS \
	-H 'Authorization: Basic YWRtaW46YWRtaW4=' \
	'http://grafana:3000/api/search' \
| jq -r '.[].uid' - \
| parallel " \
	curl -sS \
		-H 'Authorization: Basic YWRtaW46YWRtaW4=' \
		'http://grafana:3000/api/dashboards/uid/{}' \
	> '{}.json' \
"
