#!/usr/bin/env make

pre-flight: override nextcloud_admin_user ?= nextcloud
pre-flight: override nextcloud_admin_password ?= nextcloud
pre-flight: override postgres_user ?= postgres
pre-flight: override postgres_password ?= nextcloud
pre-flight: override postgres_db ?= ${postgres_user}
pre-flight:
	@echo '${nextcloud_admin_user}' > 'nextcloud_admin_user.txt'
	@echo '${nextcloud_admin_password}' > 'nextcloud_admin_password.txt'
	@echo '${postgres_user}' > 'postgres_user.txt'
	@echo '${postgres_password}' > 'postgres_password.txt'
	@echo '${postgres_db}' > 'postgres_db.txt'

firewalld-open: override service_name ?= nextcloud
firewalld-open: override port ?= 8080
firewalld-open: ${shell which 'firewall-cmd'}
	@sudo firewall-cmd --permanent --new-service '${service_name}'
	@sudo firewall-cmd --permanent --service '${service_name}' --set-description 'FIXME'
	@sudo firewall-cmd --permanent --service '${service_name}' --set-short 'FIXME'
	@sudo firewall-cmd --permanent --service '${service_name}' --add-port '${port}/tcp'
	@sudo firewall-cmd --permanent --add-service '${service_name}'
	@sudo firewall-cmd --reload

composition-go-brrr: ${shell which 'docker-compose'} pre-flight
	@docker-compose up -d
