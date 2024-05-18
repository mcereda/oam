#!/usr/bin/env make

pre-flight:
	@mkdir -pv 'consume' 'export'

firewalld-open: override service_name ?= paperless-ngx
firewalld-open: override service_port ?= 8000
firewalld-open: ${shell which 'firewall-cmd'}
	@sudo firewall-cmd --permanent --new-service '${service_name}'
	@sudo firewall-cmd --permanent --service '${service_name}' --set-description 'FIXME'
	@sudo firewall-cmd --permanent --service '${service_name}' --set-short 'FIXME'
	@sudo firewall-cmd --permanent --service '${service_name}' --add-port '${service_port}/tcp'
	@sudo firewall-cmd --permanent --add-service '${service_name}'
	@sudo firewall-cmd --reload

paperless-go-brrr: ${shell which 'docker-compose'} pre-flight
	@docker-compose up -d
