#!/usr/bin/env fish

# Connect to the API
curl --insecure --user 'admin:someCustomStr0ng!Password' 'https://localhost:9200/_cluster/health?pretty'
awscurl --service 'es' 'https://search-domain.eu-west-1.es.amazonaws.com/_cluster/health?pretty'
# If sending data, also set the 'Content-Type' header
curl 'https://localhost:9200/someIndex/_search?pretty' \
	-ku 'admin:someCustomStr0ng!Password' \
	--header 'Content-Type: application/json' \
	--data '{"query":{"match_all":{}}}'


# Copy *all* documents from an index to another
curl 'https://localhost:9200/_reindex?pretty' --request 'POST' \
	-ku 'admin:someCustomStr0ng!Password' \
	-H 'Content-Type: application/json' \
	-d '{
		"source": {"index": "sourceIndex"},
		"dest":   {"index": "destinationIndex"}
	}'

# Copy *only missing* documents from an index to another
curl 'https://localhost:9200/_reindex?pretty' -X 'POST' \
	-ku 'admin:someCustomStr0ng!Password' \
	-H 'Content-Type: application/json' \
	-d '{
		"conflicts": "proceed",
		"source": {"index": "sourceIndex"},
		"dest": {
			"index": "destinationIndex",
			"op_type": "create"
		}
	}'

# Combine indexes into one
curl 'https://localhost:9200/_reindex?pretty' -X 'POST' \
	-ku 'admin:someCustomStr0ng!Password' \
	-H 'Content-Type: application/json' \
	-d '{
		"source": {
			"index": [
				"sourceIndex_1",
				…
				"sourceIndex_N"
			]
		},
		"dest": {"index": "destinationIndex"}
	}'
