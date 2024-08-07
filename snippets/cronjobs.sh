#!/usr/bin/env sh

systemctl --enable --now 'crond.service'
journalctl -xefu 'crond.service'

# Validate crontab files
crontab -T '/etc/cron.d/prometheus-backup'

run-parts --list '/etc/cron.daily'
run-parts --test '/etc/cron.hourly'
run-parts '/etc/cron.weekly'
