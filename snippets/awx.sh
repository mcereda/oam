#!/usr/bin/env sh

# Install the 'awx' client
pipx install 'awxkit'
pip3 install --user 'awxkit'
pip install 'git+https://github.com/ansible/awx.git@24.6.1#egg=awxkit&subdirectory=awxkit'

# Normally `awx` would require setting the configuration every command like so:
#   awx --conf.host https://awx.example.org --conf.username 'admin' --conf.password 'password' config
#   awx --conf.host https://awx.example.org --conf.username 'admin' --conf.password 'password' export --schedules

# Export settings to environment variables to avoid having to set them on the command line all the time
export TOWER_HOST='https://awx.example.org' TOWER_USERNAME='admin' TOWER_PASSWORD='password'

# Show the client configuration
awx config
awx --conf.host https://awx.example.org --conf.username 'admin' --conf.password 'password' config
TOWER_HOST='https://awx.example.org' TOWER_USERNAME='admin' TOWER_PASSWORD='password' awx config

# List all available endpoints
curl -fs --user 'admin:password' 'https://awx.example.org/api/v2/' | jq '.' -

# List jobs
awx jobs list
awx jobs list -f 'yaml'
awx jobs list -f 'human' --filter 'name,created,status'
awx jobs list -f 'jq' --filter '.results[] | .name + " is " + .status'

# Show job templates
awx job_templates list
curl -fs --user 'admin:password' 'https://awx.example.org/api/v2/job_templates/' | jq '.' -

# Modify job templates
awx job_templates modify '1' --extra_vars "@vars.yml"
awx job_templates modify '5' --extra_vars "@vars.json"

# Show notification templates
awx notification_templates list
curl -fs --user 'admin:password' 'https://awx.example.org/api/v2/notification_templates/' | jq '.' -

# Show schedules
awx schedules list
awx … schedules --schedules 'schedule-1' 'schedule-n'
curl -fs --user 'admin:password' 'https://awx.example.org/api/v2/schedules/' | jq '.' -

# Import SSH keys
awx credentials create --credential_type 'Machine' \
	--name 'My SSH Key' --user 'alice' \
	--inputs '{"username": "alice", "ssh_key_data": "@~/.ssh/id_rsa"}'

# Execute ad-hoc commands
awx ad_hoc_commands create --monitor --wait --job_type 'check' --inventory 'Localhost' 'ping' --module_name 'ping'

# Export resources
awx export
awx … export --job_templates 'job-template-1' 'job-template-n' --schedules
awx … export --users 'admin' '42'

# Import resources
awx import < 'resources.json'

# Create and launch job templates
awx projects create --wait \
	--organization '1' --name='Example Project' \
	--scm_type 'git' --scm_url 'https://github.com/ansible/ansible-tower-samples' \
	-f 'human' \
&& awx job_templates create \
	--name='Example Job Template' --project 'Example Project' \
	--playbook 'hello_world.yml' --inventory 'Demo Inventory' \
	-f 'human' \
&& awx job_templates launch 'Example Job Template' --monitor -f 'human'
