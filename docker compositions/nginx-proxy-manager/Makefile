#!/usr/bin/env make

pre-flight:
	@mkdir -pv 'data' 'letsencrypt'

firewalld-open: override service_name ?= nginx-proxy-manager
firewalld-open: override http_port ?= 80
firewalld-open: override https_port ?= 443
firewalld-open: override webui_port ?= 81
firewalld-open: ${shell which 'firewall-cmd'}
	@sudo firewall-cmd --permanent --new-service '${service_name}'
	@sudo firewall-cmd --permanent --service '${service_name}' --set-description 'FIXME'
	@sudo firewall-cmd --permanent --service '${service_name}' --set-short 'FIXME'
	@sudo firewall-cmd --permanent --service '${service_name}' --add-port '${http_port}/tcp'
	@sudo firewall-cmd --permanent --service '${service_name}' --add-port '${https_port}/tcp'
	@sudo firewall-cmd --permanent --service '${service_name}' --add-port '${webui_port}/tcp'
	@sudo firewall-cmd --permanent --add-service '${service_name}'
	@sudo firewall-cmd --reload

composition-go-brrr: ${shell which 'docker-compose'} pre-flight
	@docker-compose up -d
