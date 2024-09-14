#!/usr/bin/env make

firewalld-open: override service_name ?= nextcloud
firewalld-open: override port ?= 8080
firewalld-open: ${shell which 'firewall-cmd'}
	@sudo firewall-cmd --permanent --new-service '${service_name}'
	@sudo firewall-cmd --permanent --service '${service_name}' --set-description 'FIXME'
	@sudo firewall-cmd --permanent --service '${service_name}' --set-short 'FIXME'
	@sudo firewall-cmd --permanent --service '${service_name}' --add-port '${port}/tcp'
	@sudo firewall-cmd --permanent --add-service '${service_name}'
	@sudo firewall-cmd --reload

composition-go-brrr: ${shell which 'docker-compose'}
	@docker-compose up -d
