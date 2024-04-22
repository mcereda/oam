#!make

override venv ?= ${shell git rev-parse --show-toplevel}/.venv

create-venv: override python_version ?= 3.12
create-venv: ${shell which 'python${python_version}'}
	@python${python_version} -m 'venv' '${venv}'
	@source '${venv}/bin/activate' && pip --require-virtualenv install -r 'requirements.txt'

recreate-venv:
	@rm -r '${venv}'
	@${MAKE} create-venv
