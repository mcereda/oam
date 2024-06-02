#!/usr/bin/env sh

helm --namespace 'gitlab' upgrade --install --create-namespace --version '0.64.1' --repo 'https://charts.gitlab.io' \
	'gitlab-runner' -f 'values.gitlab-runner.yml' 'gitlab/gitlab-runner'

gitlab-runner register --url "https://gitlab.com/" --non-interactive --executor "shell" --token "glrt-…"

gitlab-runner exec docker \
	--env 'AWS_ACCESS_KEY_ID=AKIA…' --env 'AWS_SECRET_ACCESS_KEY=FsN4…' --env 'AWS_REGION=eu-west-1' \
	--env 'DOCKER_AUTH_CONFIG={ "credsStore": "ecr-login" }' \
	--docker-volumes "$HOME/.aws/credentials:/root/.aws/credentials:ro" \
	'pulumi preview'
