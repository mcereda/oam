#!/usr/bin/env sh

# Generate example configuration files with entries disabled
ansible-config init --disabled > 'ansible.cfg'
ansible-config init --disabled -t 'all' > 'ansible.cfg'

# Show the current configuration
ansible-config dump

# List hosts
ansible-inventory -i 'aws_ec2.yml' --list
ansible-playbook -i 'self-hosting.yml' 'gitlab.yml' --list-hosts
ansible -i 'webservers.yml' all --list-hosts

# Show hosts' ansible facts
ansible -i 'inventory.yml' -m 'setup' all
ansible -i '192.168.1.34,gitlab.lan,' -m 'setup' 'gitlab.lan' -u 'admin'
ansible -i 'localhost,' -c 'local' -km 'setup' 'localhost'

# List tasks what would be executed
ansible-playbook 'gitlab.yml' --list-tasks
ansible-playbook 'gitlab.yml' --list-tasks --tags 'configuration,packages'
ansible-playbook 'gitlab.yml' --list-tasks --skip-tags 'system,user'

# List installed collections
ansible-galaxy collection list

# Install collections
ansible-galaxy collection install 'community.general'
ansible-galaxy collection install 'amazon.aws:9.1.0' '/path/to/collection' 'git+file:///path/to/collection.git'
ansible-galaxy collection install -r 'requirements.yml'

# Create new roles
ansible-galaxy init 'gitlab'
ansible-galaxy role init 'my_role'
ansible-galaxy role init --type 'container' --init-path 'gitlab' 'name'

# Run playbooks
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
ansible-runner -p 'test_play.yml' --container-image 'example-ee:latest'

# Run playbooks within Execution Environments.
# Use the '=' between options and their arguments
ansible-runner run \
    --container-volume-mount "$HOME/.aws:/runner/.aws:ro" \
	--container-image '012345678901.dkr.ecr.eu-west-1.amazonaws.com/ansible-ee:1.2'
    --process-isolation --process-isolation-executable 'docker' \
    '.' --playbook 'playbook.yml' -i 'inventory.ini'
ansible-navigator run 'playbook.yml' --execution-environment-image='ee/image'
ansible-navigator \
	--container-options='--platform=linux/amd64' --pull-policy='missing' \
	--mode='stdout' \
	--execution-environment-volume-mounts="$HOME/.aws:/runner/.aws:ro" \
	--set-environment-variable='ANSIBLE_VAULT_PASSWORD_FILE=vault.passwd.txt' \
	--set-environment-variable='AWS_DEFAULT_REGION=eu-west-1' \
	--pass-environment-variable='AWS_PROFILE' \
	run \
		--enable-prompts -i 'localhost,' \
		'playbook.yml' \
			-DC -c 'local'

# Debug runs
ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-playbook …

# Time task execution
ANSIBLE_CALLBACKS_ENABLED='profile_tasks' ansible-playbook …

# Validate playbooks
ansible-playbook 'path/to/playbook.yml' --syntax-check

# Ad-hoc commands
ansible -i 'hosts.yml' -m 'ping' 'all'
ansible -i 'host-1,host-n,' 'hostRegex' -m 'ansible.builtin.shell' -a 'echo $TERM'
ansible -i 'localhost,' -c 'local' 'localhost' -m 'ansible.builtin.copy' -a 'src=/tmp/src dest=/tmp/dest'
ansible -i 'localhost,' -c 'local' -m 'debug' -a 'msg="{{ (60 / 2) | int }}"' 'localhost'
venv/bin/ansible -i 'localhost ansible_python_interpreter=venv/bin/python,' -c 'local' 'localhost' \
	-m 'community.postgresql.postgresql_query' \
	-a 'login_host=host.fqdn login_user=postgres login_password=password login_db=postgres query="SELECT 1;"'
ansible -i 'localhost,' -c 'local' -Cvvv 'localhost' \
	-m 'ansible.builtin.template' -a 'src=anonymizer/templates/anonymize_data.sql.j2 dest=/tmp/anonymize_data.sql' \
	-e 'country=ireland' -e '{"phone_codes":{"ireland":"+353"}}'
ansible-runner run '.' -m 'debug' -a 'msg=hello' --hosts 'localhost'
ansible-runner run '.' -m 'setup' --hosts 'localhost' \
	--process-isolation --process-isolation-executable 'docker' --container-image 'me/ansible-ee:1.2'

# Run roles
# FIXME: check and test
ansible-runner run 'path/to/dir' --role 'role-name' --role-var 'key1=value1 … keyN=valueN'

# Clean up artifact directories
ansible-runner run --rotate-artifacts

# Encrypt/decrypt sensitive data with Vault
ansible-vault encrypt_string --name 'command_output' 'somethingNobodyShouldKnow'
ANSIBLE_VAULT_PASSWORD='ohSuchASecurePassword' ansible-vault encrypt --output 'ssh.key' '.ssh/id_rsa'
ansible-vault view 'ssh.key.pub' --vault-password-file 'password_file.txt'
ansible-vault edit 'ssh.key.pub'
ANSIBLE_VAULT_PASSWORD_FILE='password_file.txt' ansible-vault decrypt --output '.ssh/id_rsa' 'ssh.key'
ANSIBLE_VAULT_PASSWORD_FILE='password_file.txt' ansible-navigator \
	--pass-environment-variable='ANSIBLE_VAULT_PASSWORD_FILE' run 'playbook_with_vault_encrypted_data.yml'
diff 'some_role/files/ssh.key.plain' \
	<(ansible-vault view --vault-password-file 'password_file.txt' 'some_role/files/ssh.key.enc')
echo -e '$ANSIBLE_VAULT;1.1;AES256\n386462…86436' | ansible-vault decrypt --ask-vault-password

# List available plugins
ansible-doc -t 'lookup' -l
ansible-doc -t 'strategy' -l

# Show plugin-specific docs and examples
ansible-doc -t 'lookup' 'fileglob'
ansible-doc -t 'strategy' 'linear'

# Run commands within Execution Environments
ansible-navigator exec
venv/bin/ansible-navigator --mode='stdout' --container-options='--platform=linux/amd64' \
	--execution-environment-image='012345678901.dkr.ecr.eu-west-1.amazonaws.com/infra/ansible-ee' \
	exec -- ansible-galaxy collection list
AWS_PROFILE='AnsibleTaskExecutor' venv/bin/ansible-navigator \
	--execution-environment-image='012345678901.dkr.ecr.eu-west-1.amazonaws.com/infra/ansible-ee' \
	--execution-environment-volume-mounts="$HOME/.aws:/runner/.aws:ro" \
	--pass-environment-variable='AWS_PROFILE' \
	--set-environment-variable='AWS_DEFAULT_REGION=eu-west-1' \
	exec -- aws sts get-caller-identity --no-cli-pager
