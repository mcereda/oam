#!/usr/bin/env sh

# Load keys from '${HOME}/.ssh' and add them to the agent
eval $(ssh-agent) && ssh-add

# Connect
ssh 'desktop.lan'
ssh 'ec2-user@172.31.42.42' -i '.ssh/aws.key'
