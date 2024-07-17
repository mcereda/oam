#!/usr/bin/env sh

helm --namespace 'gitlab' upgrade --install --create-namespace --version '0.64.1' --repo 'https://charts.gitlab.io' \
	'gitlab-runner' -f 'values.gitlab-runner.yml' 'gitlab/gitlab-runner'

# register with token
gitlab-runner register --url 'https://gitlab.com/' --non-interactive --executor 'shell' --token 'glrt-…'
# register with registration token: deprecated
gitlab-runner register --url 'https://gitlab.example.com' --registration-token 'abc…' -n \
	--name 'gitlab-aws-autoscaler' --executor 'docker+machine' --docker-image 'alpine'

gitlab-runner exec docker \
	--env 'AWS_ACCESS_KEY_ID=AKIA…' --env 'AWS_SECRET_ACCESS_KEY=FsN4…' --env 'AWS_REGION=eu-west-1' \
	--env 'DOCKER_AUTH_CONFIG={ "credsStore": "ecr-login" }' \
	--docker-volumes "$HOME/.aws/credentials:/root/.aws/credentials:ro" \
	'pulumi preview'

docker-machine ls
docker-machine inspect

docker-machine create --driver 'amazonec2' --amazonec2-access-key 'AKID… --amazonec2-secret-key '8T93C…' 'runner-autoscaled-01'
export AWS_ACCESS_KEY_ID='AKID…' AWS_SECRET_ACCESS_KEY='8T93C…' docker-machine create --driver 'amazonec2' 'runner-autoscaled-01'

# Connect one's Docker Client to the Docker Engine running on virtual machines
eval $(docker-machine env 'runner-hzfj7uiz-ec2-1721038998-d9d31b5a')

docker-machine rm -y 'runner-r6mo9hn8-ec2-1721049931-49793fa7'
