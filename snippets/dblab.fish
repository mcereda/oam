#!/usr/bin/env fish

# If not configured, the CLI tool needs to have those specified
dblab --url 'http://dblab.example.org:1234/' --token "$(gopass show -o 'dblab')" …

# Check logs
docker logs --since '5m' -f 'dblab_server'

# Reload the configuration
docker exec -it 'dblab_server' kill -SIGHUP '1'

# Check the running container's version
# Used to check the instance is up and running
dblab instance version
curl 'http://127.0.0.1:2345/healthz'

# Initialize the CLI client
dblab init

# Show global CLI environment configuration
dblab config show-global

# Create CLI environments
dblab config create 'staging'

# Show available CLI environments
dblab config list

# Show current CLI environment configuration
dblab config view

# Modify CLI environments
# Errors out should one specify the current set of settings
dblab config update --url --insecure=true 'staging'

# Switch CLI environments
dblab config switch 'staging'

# Get the APIs' specification
# JS page
open 'https://dblab.example.org:2345/'
open 'https://dblab.example.org:1234/api/'

# Open WebUI
open 'http://dblab.example.org:1234/'

# Get instance status, instance info, and list of clones
dblab instance status
curl 'https://dblab.example.org:2345/status' -H "Verification-Token: $(gopass show -o 'dblab')"
curl 'https://dblab.example.org:1234/api/status' -H "Verification-Token: $(gopass show -o 'dblab')"

# Show data refresh status
curl 'https://dblab.example.org:2345/instance/retrieval' -H "Verification-Token: $(gopass show -o 'dblab')"
curl 'https://dblab.example.org:1234/api/instance/retrieval' -H "Verification-Token: $(gopass show -o 'dblab')"

# List snapshots
dblab snapshot list
curl 'https://dblab.example.org:2345/snapshots' -H "Verification-Token: $(gopass show -o 'dblab')"
curl 'https://dblab.example.org:1234/api/snapshots' -H "Verification-Token: $(gopass show -o 'dblab')"

# Create clones
dblab clone create --id 'some-clone' --protected --username 'geppetto' --password 'pinocchio' --db-name 'puppetshop'
curl -X 'POST' 'https://dblab.example.org:1234/api/clone' -H "Verification-Token: $(gopass show -o 'dblab')" \
	-H 'accept: application/json' -H 'content-type: application/json' \
	-d '{
		"id": "some-clone",
		"protected": true,
		"db": {
			"username": "geppetto",
			"password": "pinocchio",
			"db_name": "puppetshop"
		}
	}'

# List clones
dblab clone list
curl 'https://dblab.example.org:2345/status' -H "Verification-Token: $(gopass show -o 'dblab')" | jq '.' -
curl 'https://dblab.example.org:1234/api/status' -H "Verification-Token: $(gopass show -o 'dblab')"

# Get clones' information
dblab clone status 'some-clone'
curl 'https://dblab.example.org:1234/clone/some-clone' -H "Verification-Token: $(gopass show -o 'dblab')"
curl 'https://dblab.example.org:1234/api/clone/some-clone' -H "Verification-Token: $(gopass show -o 'dblab')"

# Restart clones
# Only doable from the instance
docker restart 'dblab_clone_6000'

# Reset clones
# Only available via the '/api' endpoints, no direct ones
dblab clone reset --async='true' --latest='true' 'some-clone'
curl -X 'POST' 'https://dblab.example.org:1234/api/clone/some-clone/reset' \
	-H "Verification-Token: $(gopass show -o 'dblab')" \
	-H 'accept: application/json' -H 'content-type: application/json' \
	-d '{ "latest": true }'
# Reset all protected clones
curl --url 'https://dblab.example.org:2345/status' --header 'verification-token: somePassword' \
| jq -r '.cloning.clones[]|select(.protected = "true")|.id' \
| xargs -I '%%' \
	curl --request 'POST' --url 'https://dblab.example.org:1234/api/clone/%%/reset' \
        --header 'verification-token: somePassword' \
        --header 'content-type: application/json' \
        --data '{ "latest": true }'

# Unprotect clones
dblab clone update --protected='false' 'some-clone'
curl -X 'PATCH' 'https://dblab.example.org:1234/api/clone/some-clone' \
	-H "Verification-Token: $(gopass show -o 'dblab')" \
	-H 'accept: application/json' -H 'content-type: application/json' \
	-d '{ "protected": false }'

# Delete clones
dblab clone destroy 'some-clone'
curl -X 'DELETE' 'https://dblab.example.org:1234/api/clone/some-clone' -H "Verification-Token: $(gopass show -o 'dblab')"

# Get admin config in YAML format
curl 'https://dblab.example.org:1234/api/admin/config.yaml' -H "Verification-Token: $(gopass show -o 'dblab')"
