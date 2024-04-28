#!make

override inventory ?= aws_ec2.yml
override playbook ?= ansible-playbook.yml
override venv ?= .venv

create-venv: python_version ?= 3
create-venv: ${shell which 'python${python_version}'}
	@python${python_version} -m 'venv' '${venv}'
	@${venv}/bin/pip --require-virtualenv install -U -r 'requirements.txt'

check: ${venv}/bin/ansible-playbook
	@${venv}/bin/ansible-playbook -i '${inventory}' -DCvvv '${playbook}'
run: ${venv}/bin/ansible-playbook
	@${venv}/bin/ansible-playbook -i '${inventory}' -D '${playbook}'
