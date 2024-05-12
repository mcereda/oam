#!/usr/bin/env make

pre-flight:
	@mkdir -pv 'config' 'data'

firewalld-open: override service_name ?= gitea
firewalld-open: override webui_port ?= 3000
firewalld-open: override ssh_port ?= 2222
firewalld-open: ${shell which 'firewall-cmd'}
	@sudo firewall-cmd --permanent --new-service '${service_name}'
	@sudo firewall-cmd --permanent --service '${service_name}' --set-description \
		'Painless self-hosted all-in-one software development service similar to GitHub, Bitbucket and GitLab.'
	@sudo firewall-cmd --permanent --service '${service_name}' --set-short 'Private, fast and reliable DevOps platform'
	@sudo firewall-cmd --permanent --service '${service_name}' --add-port '${ssh_port}/tcp'
	@sudo firewall-cmd --permanent --service '${service_name}' --add-port '${webui_port}/tcp'
	@sudo firewall-cmd --permanent --add-service '${service_name}'
	@sudo firewall-cmd --reload

composition-go-brrr: ${shell which 'docker-compose'} pre-flight
	@docker-compose up -d
