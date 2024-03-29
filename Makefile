create-venv: override python_version ?= 3.12
create-venv:
	python${python_version} -m 'venv' '.venv'
	source '.venv/bin/activate' && pip install -r 'requirements.txt'
