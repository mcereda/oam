#!/usr/bin/env make

pre-flight:
	@mkdir -pv 'data'
	@docker compose run --rm --user 'root' 'semaphore' chown -Rv 'semaphore' '/etc/semaphore' '/var/lib/semaphore'

firewalld-open: override service_name ?= semaphore
firewalld-open: override port ?= ${shell yq -r '.services.${service_name}.ports[0]|split(":")|first' docker-compose.yml}
firewalld-open: override firewall_cmd_executable ?= ${shell which 'firewall-cmd'}
firewalld-open: ${firewall_cmd_executable}
	@sudo ${firewall_cmd_executable} --permanent --new-service '${service_name}'
	@sudo ${firewall_cmd_executable} --permanent --service '${service_name}' --set-description 'FIXME'
	@sudo ${firewall_cmd_executable} --permanent --service '${service_name}' --set-short 'FIXME'
	@sudo ${firewall_cmd_executable} --permanent --service '${service_name}' --add-port '${port}/tcp'
	@sudo ${firewall_cmd_executable} --permanent --add-service '${service_name}'
	@sudo ${firewall_cmd_executable} --reload

composition-go-brrr: ${shell which 'docker-compose'} pre-flight
	@docker-compose up -d
