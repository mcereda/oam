#!/usr/bin/env sh

helm --namespace 'gitlab' upgrade --install --create-namespace --version '0.64.1' --repo 'https://charts.gitlab.io' \
	'gitlab-runner' -f 'values.gitlab-runner.yml' 'gitlab/gitlab-runner'

diff -y <(helm show values 'gitlab/gitlab-runner' --version '0.64.2') <(helm show values 'gitlab/gitlab-runner' --version '0.68.1')


# Run
gitlab-runner exec docker \
	--env 'AWS_ACCESS_KEY_ID=AKIA…' --env 'AWS_SECRET_ACCESS_KEY=FsN4…' --env 'AWS_REGION=eu-west-1' \
	--env 'DOCKER_AUTH_CONFIG={ "credsStore": "ecr-login" }' \
	--docker-volumes "$HOME/.aws/credentials:/root/.aws/credentials:ro" \
	'pulumi preview'


# Register with token
gitlab-runner register --url 'https://gitlab.com/' --non-interactive --executor 'shell' --token 'glrt-…'
curl -fsX 'POST' https://gitlab.com/api/v4/user/runners -H 'PRIVATE-TOKEN: glpat-m-…' \
	-d 'runner_type=instance_type' -d "tag_list=small,instance" -d 'run_untagged=false'
# Register with registration token: deprecated
gitlab-runner register --url 'https://gitlab.example.com' --registration-token 'abc…' -n \
	--name 'gitlab-aws-autoscaler' --executor 'docker+machine' --docker-image 'alpine'


# Just list configured runners
gitlab-runner list -c '/etc/gitlab-runner/config.toml'
curl -fs 'https://gitlab.com/api/v4/runners/all?per_page=100' -H 'PRIVATE-TOKEN: glpat-m-…'

# Check configured runners can connect to the main instance
gitlab-runner verify -c '/etc/gitlab-runner/config.toml'
# Also delete runners that have been removed from the main instance
gitlab-runner verify … --delete

# Unregister offline runners
curl -fs 'https://gitlab.com/api/v4/runners/all?status=offline&per_page=100' -H 'PRIVATE-TOKEN: glpat-m-…' \
| jq '.[].id' \
| xargs -I 'runner_id' curl -fsX 'DELETE' "https://gitlab.com/api/v4/runners/runner_id" 'PRIVATE-TOKEN: glpat-m-…'

# Force reloading the configuration file
sudo kill -HUP $(pidof 'gitlab-runner')
sudo kill -s 'SIGHUP' $(pgrep 'gitlab-runner')

# Stop accepting new builds and exit as soon as currently running builds finish
# A.K.A. graceful shutdown
sudo kill -QUIT $(pgrep 'gitlab-runner')
sudo kill -s 'SIGQUIT' $(pidof 'gitlab-runner')

# Pause active runners
curl -fs 'https://gitlab.com/api/v4/runners/all?per_page=100&paused=false' -H 'PRIVATE-TOKEN: glpat-m-…' \
| jq '.[].id' - \
| xargs -I '{}' curl -fsX 'PUT' 'https://gitlab.com/api/v4/runners/{}' -H 'PRIVATE-TOKEN: glpat-m-…' -F 'paused=true'


###
# docker+machine executor
# --------------------------------------
###

docker-machine ls
docker-machine inspect

docker-machine create --driver 'amazonec2' --amazonec2-access-key 'AKID…' --amazonec2-secret-key '8T93C…' 'runner-autoscaled-01'
export AWS_ACCESS_KEY_ID='AKID…' AWS_SECRET_ACCESS_KEY='8T93C…' docker-machine create --driver 'amazonec2' 'runner-autoscaled-01'

# Connect one's Docker Client to the Docker Engine running on virtual machines
eval $(docker-machine env 'runner-hzfj7uiz-ec2-1721038998-d9d31b5a')

docker-machine rm -y 'runner-r6mo9hn8-ec2-1721049931-49793fa7'


###
# docker-autoscaler executor
# instance executor
# --------------------------------------
###

# Install plugins from the OCI registry distribution
gitlab-runner fleeting install

# List plugins with version
gitlab-runner fleeting list

# Sign in to private registries
gitlab-runner fleeting login
