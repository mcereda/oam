#!/usr/bin/env make

override venv ?= ${shell git rev-parse --show-toplevel}/.venv

create-venv: override python_version ?= 3.11
ifeq "${shell uname}" "Darwin"
create-venv: python_executable = ${shell which 'python${python_version}'}
else
create-venv: python_executable = ${shell which --tty-only --show-dot --show-tilde 'python${python_version}'}
endif
create-venv: ${python_executable}
	@${python_executable} -m 'venv' '${venv}'
	@${venv}/bin/pip --require-virtualenv install -r 'requirements.txt'

recreate-venv:
	@rm -rf '${venv}'
	@${MAKE} create-venv

update-venv: ${venv}/bin/pip
	@${venv}/bin/pip freeze -l --require-virtualenv | sed 's/==/>=/' \
	| xargs ${venv}/bin/pip --require-virtualenv install -U
