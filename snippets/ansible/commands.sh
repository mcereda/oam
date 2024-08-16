#!/usr/bin/env sh

# Generate example configuration files with entries disabled.
ansible-config init --disabled > 'ansible.cfg'
ansible-config init --disabled -t 'all' > 'ansible.cfg'

# Show the current configuration.
ansible-config dump

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
ansible-galaxy role init 'my_role'
ansible-galaxy role init --type 'container' --init-path 'gitlab' 'name'

# Apply changes.
ansible-playbook -DK 'ansible/playbooks/local-network.hosts.configure.yml' \
	-i 'inventory/local-network.ini' -l 'workstation.lan' -c 'local' -C
ansible-playbook 'gitlab.yml' \
	-i 'aws_ec2.yml' -e 'ansible_aws_ssm_plugin=/usr/local/sessionmanagerplugin/bin/session-manager-plugin' \
	-D --step
ansible-playbook 'prometheus.yml' \
	-i 'aws_ec2.yml' -e 'ansible_aws_ssm_plugin=/usr/local/sessionmanagerplugin/bin/session-manager-plugin' \
	-D -t 'cron' -l 'i-0123456789abcdef0' -C
ansible-playbook 'playbook.yaml' \
	-e 'ansible_aws_ssm_plugin=/usr/local/sessionmanagerplugin/bin/session-manager-plugin' \
	-e 'ansible_connection=aws_ssm' -e 'ansible_aws_ssm_bucket_name=ssm-bucket' -e 'ansible_aws_ssm_region=eu-west-1' \
	-e 'ansible_remote_tmp=/tmp/.ansible-\${USER}/tmp' \
	-i 'i-0123456789abcdef0,' -D
ansible-playbook -i 'localhost,' -c 'local' -Dvvv 'playbook.yml' -t 'container_registry' --ask-vault-pass

ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-playbook …
ANSIBLE_CALLBACKS_ENABLED='profile_tasks' ansible-playbook …

ansible-playbook 'path/to/playbook.yml' --syntax-check

# Ad-hoc commands.
ansible -i 'hosts.yml' -m 'ping' 'all'
ansible -i 'host-1,host-n,' 'hostRegex' -m 'ansible.builtin.shell' -a 'echo $TERM'
ansible -i 'localhost ansible_python_interpreter=venv/bin/python3,' -c 'local' -m 'ansible.builtin.copy' -a 'src=/tmp/src' -a 'dest=/tmp/dest' 'localhost'

ansible-vault encrypt_string --name 'command_output' 'somethingNobodyShouldKnow'
ansible-vault encrypt --output 'ssh.key' '.ssh/id_rsa'
ansible-vault view 'ssh.key.pub' --vault-password-file 'password_file.txt'
ansible-vault edit 'ssh.key.pub'
ANSIBLE_VAULT_PASSWORD_FILE='password_file.txt' ansible-vault decrypt --output '.ssh/id_rsa' 'ssh.key'
diff 'some_role/files/ssh.key.plain' <(ansible-vault view --vault-password-file 'password_file' 'some_role/files/ssh.key.enc')
