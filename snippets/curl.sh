#!/usr/bin/env sh

# Sources:
# - https://everything.curl.dev/usingcurl/connections/name.html


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
