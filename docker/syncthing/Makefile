#!/usr/bin/env make

pre-flight:
	@mkdir -pv 'config' 'data'

firewalld-open: ${shell which 'firewall-cmd'}
	@sudo firewall-cmd --permanent --add-service 'syncthing'
	@sudo firewall-cmd --permanent --add-service 'syncthing-gui'
	@sudo firewall-cmd --reload

syncthing-go-brrr: ${shell which 'docker-compose'} pre-flight
	@docker-compose up -d
