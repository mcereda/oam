#!/usr/bin/env sh

# Sources:
# - https://everything.curl.dev/usingcurl/connections/name.html

# Get one's own public IP
curl 'ipconfig.io'
curl -fs 'https://ipconfig.io/json' | jq -r '.ip' -

# Specify data for the request
curl --request 'POST' --url 'https://redash.example.org/api/data_sources' --header 'Authorization: Key aa…00' \
	--data '{
		"name": "Some PostgreSQL Data Source",
		"type": "pg",
		"options": {
			"host": "db.example.org",
			"port": 5432,
			"dbname": "postgres",
			"user": "redash",
			"password": "SomeStr0ngPa$$word"
		}
	}'
curl -X 'POST' 'https://redash.example.org/api/data_sources' -H 'Authorization: Key aa…00' -d '{…}'

# Use different names.
# Kinda like '--resolve' but to aliases and supports ports.
curl --connect-to 'super.fake.domain:443:localhost:8443' 'https://super.fake.domain'

# Forcefully resolve hosts to given addresses.
# The resolution *must* be an address, not an FQDN.
curl --resolve 'super.fake.domain:8443:127.0.0.1' 'https://super.fake.domain:8443'


curl -fs 'https://gitlab.com/api/v4/runners/all?per_page=100&paused=false' -H 'PRIVATE-TOKEN: glpat-m-…'
curl --url 'https://gitlab.com/api/v4/runners/all' \
	--fail --silent \
	--header 'PRIVATE-TOKEN: glpat-m-…' \
	--url-query 'per_page=100' --url-query 'paused=false'

curl -fsX 'PUT' 'https://gitlab.com/api/v4/runners/{}' -H 'PRIVATE-TOKEN: glpat-m-…' -F 'paused=true'
curl --fail --silent --request 'PUT' 'https://gitlab.com/api/v4/runners/{}' \
	--header 'PRIVATE-TOKEN: glpat-m-…' --form 'paused=true'


curl -v --cookie "USER_TOKEN=Yes" http://127.0.0.1:5000/

curl --head --url 'localhost:5000/healthz'
curl -I 'localhost:5000/healthz'
