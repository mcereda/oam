#!/usr/bin/env make

override venv ?= ${shell git rev-parse --show-toplevel}/.venv

create-venv: override python_version ?= 3
create-venv: ${shell which 'python${python_version}'}
	@python${python_version} -m 'venv' '${venv}'
	@${venv}/bin/pip --require-virtualenv install -r 'requirements.txt'

recreate-venv:
	@rm -r '${venv}'
	@${MAKE} create-venv

update-venv: ${venv}/bin/pip
	@${venv}/bin/pip freeze -l --require-virtualenv | sed 's/==/>=/' \
	| xargs ${venv}/bin/pip --require-virtualenv install -U
