#!/usr/bin/env make

firewalld-open: override service_name ?= baikal
firewalld-open: override service_port ?= 80
firewalld-open: ${shell which 'firewall-cmd'}
	@sudo firewall-cmd --permanent --new-service '${service_name}'
	@sudo firewall-cmd --permanent --service '${service_name}' --set-description \
		'Painless self-hosted all-in-one software development service similar to GitHub, Bitbucket and GitLab.'
	@sudo firewall-cmd --permanent --service '${service_name}' --set-short 'Private, fast and reliable DevOps platform'
	@sudo firewall-cmd --permanent --service '${service_name}' --add-port '${service_port}/tcp'
	@sudo firewall-cmd --permanent --add-service '${service_name}'
	@sudo firewall-cmd --reload

composition-go-brrr: ${shell which 'docker-compose'}
	@docker-compose up -d
