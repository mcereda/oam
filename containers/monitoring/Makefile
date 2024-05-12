#!/usr/bin/env make

firewalld-open-node-exporter: override service_name ?= prometheus-node-exporter
firewalld-open-node-exporter: override port ?= 9100
firewalld-open-node-exporter: ${shell which 'firewall-cmd'}
	@sudo firewall-cmd --permanent --new-service '${service_name}'
	@sudo firewall-cmd --permanent --service '${service_name}' --set-description 'FIXME'
	@sudo firewall-cmd --permanent --service '${service_name}' --set-short 'FIXME'
	@sudo firewall-cmd --permanent --service '${service_name}' --add-port '${port}/tcp'
	@sudo firewall-cmd --permanent --add-service '${service_name}'
	@sudo firewall-cmd --reload

firewalld-open-prometheus: ${shell which 'firewall-cmd'}
	@sudo firewall-cmd --permanent --add-service 'prometheus'
	@sudo firewall-cmd --reload

firewalld-open-grafana: ${shell which 'firewall-cmd'}
	@sudo firewall-cmd --permanent --add-service 'grafana'
	@sudo firewall-cmd --reload

firewalld-open: firewalld-open-node-exporter firewalld-open-prometheus firewalld-open-grafana

composition-go-brrr: ${shell which 'docker-compose'}
	@docker-compose up -d
