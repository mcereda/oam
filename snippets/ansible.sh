#!/usr/bin/env sh

# Generate example configuration files with entries disabled.
ansible-config init --disabled > 'ansible.cfg'
ansible-config init --disabled -t 'all' > 'ansible.cfg'

# List hosts.
ansible-inventory -i 'aws_ec2.yml' --list
ansible-playbook -i 'self-hosting.yml' 'gitlab.yml' --list-hosts
ansible -i 'webservers.yml' all --list-hosts

# Show hosts' ansible facts.
ansible -i 'inventory.yml' -m 'setup' all
ansible -i '192.168.1.34,gitlab.lan,' -m 'setup' 'gitlab.lan' -u 'admin'
ansible -i 'localhost,' -c 'local' -km 'setup' 'localhost'

# List tasks what would be executed.
ansible-playbook 'gitlab.yml' --list-tasks
ansible-playbook 'gitlab.yml' --list-tasks --tags 'configuration,packages'
ansible-playbook 'gitlab.yml' --list-tasks --skip-tags 'system,user'

# Create new roles.
ansible-galaxy init 'gitlab'
ansible-galaxy role init --type 'container' --init-path 'gitlab' 'name'

# Apply changes.
ansible-playbook \
	-i 'aws_ec2.yml' -e 'ansible_aws_ssm_plugin=/usr/local/sessionmanagerplugin/bin/session-manager-plugin' \
	-D --step \
	'gitlab.yml'
