#!/usr/bin/env sh

cat > .pre-commit-config.yaml <<-EOF
	repos:
	  - repo: https://github.com/pre-commit/pre-commit-hooks
	    rev: v4.0.1
	    hooks:
	      - id: trailing-whitespace
	      - id: end-of-file-fixer
	      - id: check-yaml
	  - repo: https://github.com/ansible-community/ansible-lint
	    rev: v5.2.1
	    hooks:
	      - id: ansible-lint
EOF

pre-commit install
