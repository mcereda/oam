#!/usr/bin/env fish

docker run --rm -it 'okigan/awscurl' \
	-- \
	--region 'eu-south-1' --service 'aps' \
	--access_key "$AWS_ACCESS_KEY_ID" --secret_key "$AWS_SECRET_ACCESS_KEY" \
	'https://aps.workspace.url/api/v1/query/api/v1/query?query=up'

awscurl --service 'es' 'https://search-domain.eu-west-1.es.amazonaws.com/_cluster/health?pretty'

awscurl --region 'eu-south-1' --service 'aps' -X 'POST' 'https://aps.workspace.url/api/v1/query?query=up'
awscurl --service 'aps' 'https://aps.workspace.url/api/v1/query/api/v1/query' \
	-d 'query=up' -d 'time=1652382537' -d 'stats=all'
