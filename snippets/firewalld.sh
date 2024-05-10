#!/usr/bin/env sh

# Open ports.
sudo firewall-cmd --add-port='3000/tcp' --zone='public' --permanent
sudo firewall-cmd --add-port='2222/tcp' --zone='public'


# List pre-loaded, available services.
sudo firewall-cmd --get-services

# List allowed services.
sudo firewall-cmd --list-services

# Add services.
sudo firewall-cmd --permanent --new-service 'gitea' \
&& sudo firewall-cmd --permanent --service 'gitea' --set-description \
	'Painless self-hosted all-in-one software development service similar to GitHub, Bitbucket and GitLab.' \
&& sudo firewall-cmd --permanent --service 'gitea' --set-short 'Private, fast and reliable DevOps platform' \
&& sudo firewall-cmd --permanent --service 'gitea' --add-port '2222/tcp' \
&& sudo firewall-cmd --permanent --service 'gitea' --add-port '3000/tcp'

# Allow services.
sudo firewall-cmd --permanent --add-service 'gitea'


# Reload.
sudo firewall-cmd --reload
sudo firewall-cmd --complete-reload
sudo killall -HUP 'firewalld'


# List allowed flows.
sudo firewall-cmd --list-all
