#!/usr/bin/env fish

# List the current application settings of the GitLab instance.
curl -sH 'PRIVATE-TOKEN: glpat-m-…' 'https://gitlab.fqdn/api/v4/application/settings' | jq

# Show the diff in settings between two instances
jd -color \
	( curl -ksH 'PRIVATE-TOKEN: glpat-abcdefghijklmnopqrst' 'https://gitlab.test.fqdn/api/v4/application/settings' | jq | psub ) \
	( curl -ksH 'PRIVATE-TOKEN: glpat-0123456789abcdefghij' 'https://gitlab.prod.fqdn/api/v4/application/settings' | jq | psub)
