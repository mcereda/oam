#!/usr/bin/env

# configure access
set -x 'TOWER_HOST' 'https://awx.example.com/'
set -x 'TOWER_USERNAME' 'admin'
set -x 'TOWER_PASSWORD' 'someReallyStrongPasswordInnit?'

# show the current configuration
awx config

# show info about the calling user
awx me

# terminate sessions
awx-manage expire_sessions
awx-manage expire_sessions --user 'leonardo'

# delete expired sessions
awx-manage clearsessions

###
# Applications
# --------------------------------------
# external access based on token
###

# list applications
awx applications list --all | jq '.results[].name' -

###
# Job templates
# --------------------------------------
###

# list job templates
awx job_templates list --all  | jq '.results[].name' -
awx system_job_templates list --all  | jq '.results[].name' -

###
# Projects
# --------------------------------------
# collections of ansible playbooks
###

# list projects
awx project list --all | jq '.results[].name' -
awx project list --name 'something' -f 'jq' | jq '.results[].id' -

# update projects
awx projects update '4'
awx projects update --monitor --interval '3' '4'

###
# Schedules
# --------------------------------------
###

# list schedules
awx schedules list --all | jq '.results[].name'
