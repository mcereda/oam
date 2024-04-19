#!sh

gitlab-runner exec docker \
	--env 'AWS_ACCESS_KEY_ID=AKIA…' --env 'AWS_SECRET_ACCESS_KEY=FsN4…' --env 'AWS_REGION=eu-west-1' \
	--env 'DOCKER_AUTH_CONFIG={ "credsStore": "ecr-login" }' \
	--docker-volumes "$HOME/.aws/credentials:/root/.aws/credentials:ro" \
	'pulumi preview'
