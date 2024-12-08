#!/usr/bin/env fish

# Create clones
curl -X 'POST' 'https://dblab.company.com:1234/api/clone' -H "Verification-Token: $(gopass show -o 'dblab')" \
	-H 'accept: application/json' -H 'content-type: application/json' \
	-d '{
		"id": "smth",
		"protected": true,
		"db": {
			"username": "master",
			"password": "ofPuppets",
			"db_name": "puppet"
		}
	}'

# Get clones' information
curl 'https://dblab.company.com:1234/api/clone/smth' -H "Verification-Token: $(gopass show -o 'dblab')"
dblab --url 'http://dblab.company.com:1234/' --token "$(gopass show -o 'dblab')" clone status 'smth'

# Reset clones
curl -X 'POST' 'https://dblab.company.com:1234/api/clone/smth/reset' -H "Verification-Token: $(gopass show -o 'dblab')" \
	-H 'accept: application/json' -H 'content-type: application/json' \
	-d '{ "latest": true }'

# Unprotect clones
curl -X 'PATCH' 'https://dblab.company.com:1234/api/clone/smth' -H "Verification-Token: $(gopass show -o 'dblab')" \
	-H 'accept: application/json' -H 'content-type: application/json' \
	-d '{ "protected": false }'

# Delete clones
curl -X 'DELETE' 'https://dblab.company.com:1234/api/clone/smth' -H "Verification-Token: $(gopass show -o 'dblab')"
