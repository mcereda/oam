#!/usr/bin/env make

pre-flight:
	@mkdir -p 'config' 'data'

gitea-go-brrr: ${shell which 'docker-compose'} pre-flight
	@docker-compose up -d
