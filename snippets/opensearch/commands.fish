#!/usr/bin/env fish

# Run dashboards locally
docker run --rm --name 'opensearch-dashboards' --publish '5601' \
	--env OPENSEARCH_HOSTS='["https://node1:9200","https://node2:9200"]' \
	'public.ecr.aws/opensearchproject/opensearch-dashboards:2.19'

# Connect to the API
curl --insecure --user 'admin:someCustomStr0ng!Password' 'https://localhost:9200/_cluster/health?pretty'
awscurl --service 'es' 'https://search-domain.eu-west-1.es.amazonaws.com/_cluster/health?pretty'
# If sending data, also set the 'Content-Type' header
curl 'https://localhost:9200/someIndex/_search?pretty' \
	-ku 'admin:someCustomStr0ng!Password' \
	--header 'Content-Type: application/json' \
	--data '{"query":{"match_all":{}}}'

# List indices in cold storage matching a filter
awscurl --service 'es' \
	'https://search-aws-domain-abcdefghijklmnopqrstuvwxyz.eu-west-1.es.amazonaws.com/_cold/indices/_search' \
	-d '{ "filters": { "index_pattern": ".app-logs-production-*" } }' \
| jq -r '.indices[].index' - \
| tr '\n' ','

# Migrate all indices from ultrawarm to hot storage
# only aws-managed opensearch domains
awscurl --service 'es' \
	'https://search-aws-domain-abcdefghijklmnopqrstuvwxyz.eu-west-1.es.amazonaws.com/_cat/indices/_warm' \
| grep 'app-cwl-' | sort | cut -d ' ' -f 3 \
| xargs -pI'%%' awscurl --service 'es' --request 'POST' \
	'https://search-aws-domain-abcdefghijklmnopqrstuvwxyz.eu-west-1.es.amazonaws.com/_ultrawarm/migration/%%/_hot'

# Take snapshots of indices in ultrawarm
# only one per request, no storage tier mixing allowed
seq 83 72 \
| xargs -pI '%%' awscurl --service 'es' --request 'POST' \
	'https://search-aws-domain-abcdefghijklmnopqrstuvwxyz.eu-west-1.es.amazonaws.com/_snapshot/repo/app-logs-0000%%' \
	-d '{"indices": "app-logs-0000%%", "include_global_state": false}'

# Keep an eye on snapshots
watch -n '5' " \
	awscurl --service 'es' \
		'https://search-aws-domain-abcdefghijklmnopqrstuvwxyz.eu-west-1.es.amazonaws.com/_snapshot/_status' \
	| jq '.snapshots[]?|{\"name\":.snapshot,\"state\":.state,\"shards\":.shards_stats}' - \
"

# Delete indices that have been snapshotted
awscurl --service 'es' \
	'https://search-aws-domain-abcdefghijklmnopqrstuvwxyz.eu-west-1.es.amazonaws.com/_snapshot/some-repo/some-snap' \
| jq -r '.snapshots[].indices[]' \
| sort \
| xargs -tI '%%' awscurl --service 'es' --request 'DELETE' \
	'https://search-aws-domain-abcdefghijklmnopqrstuvwxyz.eu-west-1.es.amazonaws.com/%%'
