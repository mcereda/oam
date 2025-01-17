#!/usr/bin/env sh

##
# Installation - start
# --------------------------------------
# Instance OS: AmazonLinux 2023
# Instance size: t4g.xlarge
# Source: https://about.gitlab.com/install/#amazonlinux-2023
##

sudo systemctl is-active sshd.service
sudo systemctl is-enabled sshd.service
sudo systemctl enable --now 'sshd.service'

# Firewalld was not available on the instance
# ---
# sudo systemctl enable --now 'firewalld.service'
# sudo firewall-cmd --permanent --add-service=http
# sudo firewall-cmd --permanent --add-service=https
# sudo systemctl reload firewalld.service

# Can be avoided if emails are not used.
sudo dnf -y install 'postfix'
sudo systemctl enable --now 'postfix.service'

# Should have been `curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | bash`, but
# blindly installing stuff from the Internet just sucks.
# Soooo, following their script…
source '/etc/os-release'
os="${ID}"
dist="${VERSION_ID}"
base_url='https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/config_file.repo'
curl -sSf "${base_url}?os=${os}&dist=${dist}&source=script" | sudo tee '/etc/yum.repos.d/gitlab_gitlab-ee.repo'
dnf -q makecache -y --disablerepo='*' --enablerepo='gitlab_gitlab-ee'
dnf -q makecache -y --disablerepo='*' --enablerepo='gitlab_gitlab-ee-source'

# For 'https://…' URLs, the package will automatically request a certificate with Let's Encrypt during installation.
# This requires inbound HTTP access and a valid hostname. You can also use your own certificate.
# To avoid this, just use 'http://…' without the final 's'.
sudo EXTERNAL_URL="http://ip-172-31-73-256.eu-south-2.compute.internal" dnf install -y 'gitlab-ee'

# File automatically removed after 24h.
sudo cat '/etc/gitlab/initial_root_password'

# Open the page.
open 'http://ip-172-31-73-256.eu-south-2.compute.internal'
xdg-open 'http://ip-172-31-73-256.eu-south-2.compute.internal'

## Installation - end ---------------- #

##
# Configuration - start
# --------------------------------------
##

# Updated config template available at
# https://gitlab.com/gitlab-org/omnibus-gitlab/blame/master/files/gitlab-config-template/gitlab.rb.template

# Local template (corresponding to the installed version) available at '/opt/gitlab/etc/gitlab.rb.template'

sudo dnf -y install 'ruby' 'vim'
sudo vim '/etc/gitlab/gitlab.rb'
sudo ruby -c '/etc/gitlab/gitlab.rb'
sudo gitlab-ctl show-config
sudo gitlab-ctl reconfigure

gitlab-rails runner '
	::Gitlab::CurrentSettings.update!(signup_enabled: false);
	::Gitlab::CurrentSettings.update!(require_admin_approval_after_user_signup: false);

	::Gitlab::CurrentSettings.update!(email_confirmation_setting: "hard");

	::Gitlab::CurrentSettings.update!(password_number_required: true);
	::Gitlab::CurrentSettings.update!(password_lowercase_required: true);
	::Gitlab::CurrentSettings.update!(password_uppercase_required: true);
'

# Configuration - end ---------------- #

##
# Maintenance - start
# --------------------------------------
##

# Check services
sudo gitlab-ctl status

# Restart services
sudo gitlab-ctl restart
sudo gitlab-ctl restart nginx

# Get logs
sudo gitlab-ctl tail
sudo gitlab-ctl tail 'prometheus'

# Backup data
sudo gitlab-backup create
sudo gitlab-backup create STRATEGY=copy

# Backup configuration
sudo gitlab-ctl backup-etc \
&& ls -t '/etc/gitlab/config_backup/' \
	| head -n '1' \
	| xargs -pI '{}' aws s3 cp '/etc/gitlab/config_backup/'{} 's3://backups/gitlab/'

# Put the instance in maintenance mode
sudo gitlab-rails runner '
	::Gitlab::CurrentSettings.update!(maintenance_mode: true);
	::Gitlab::CurrentSettings.update!(maintenance_mode_message: "New message");
'
# Take the instance out of maintenance mode
sudo gitlab-rails runner '::Gitlab::CurrentSettings.update!(maintenance_mode: false);'

# Package upgrade
sudo yum check-update
sudo yum info 'gitlab-ee'                                              # informational
sudo rpm -qa | grep 'gitlab-ee'                                        # informational
sudo yum --showduplicates list available 'gitlab-ee'
sudo gitlab-backup create                                              # not strictly necessary: the upgrade will create a partial one
sudo gitlab-ctl backup-etc
tmux new-session -A -s 'gitlab-upgrade' "sudo yum update 'gitlab-ee'"  # 'gitlab-ee-16.11.3' if version-specific
sudo gitlab-rake 'gitlab:check'

# DB version upgrade
sudo gitlab-ctl pg-upgrade
sudo gitlab-ctl pg-upgrade -V '16'
# Check there is enough disk space for two copies of the database
test $(( $(sudo du -s '/var/opt/gitlab/postgresql/data' | awk '{print $1}') * 2 )) -lt \
	$(sudo df --output='avail' --direct '/var/opt/gitlab/postgresql/data' | tail -n 1) \
&& sudo gitlab-ctl pg-upgrade -V '16'

# Password reset
sudo gitlab-rake 'gitlab:password:reset[root]'
sudo gitlab-rails console
	# --> user = User.find_by_username 'root'
	# --> user.password = 'QwerTy184'
	# --> user.password_confirmation = 'QwerTy184'
	# --> user.password_automatically_set = false
	# --> user.save!
	# --> quit
sudo gitlab-rails runner '
	user = User.find_by_username "anUsernameHere";
	new_password = "QwerTy184";
	user.password = new_password;
	user.password_confirmation = new_password;
	user.password_automatically_set = false;
	user.save!
'

# Create tokens
sudo gitlab-rails runner '
	token = User.find_by_username('root').personal_access_tokens.create(scopes: [:api, :sudo], name: 'Automation');
	token.set_token('TwentyCharacterToken.');
	token.save!
'

# Disable users' two factor authentication.
sudo gitlab-rails runner 'User.where(username: "anUsernameHere").each(&:disable_two_factor!)'
sudo gitlab-rails runner 'User.update_all(otp_required_for_login: false, encrypted_otp_secret: nil)'

## Maintenance - end ----------------- #

##
# Restore backups - start
# --------------------------------------
# Version *and* edition of the installed version must be the exact same of the
# ones from the backup.
##

sudo aws s3 cp 's3://backups/gitlab/gitlab-secrets.json' '/etc/gitlab/gitlab-secrets.json'
sudo aws s3 cp 's3://backups/gitlab/gitlab.rb' '/etc/gitlab/gitlab.rb'
sudo aws s3 cp --region=eu-east-1 \
	's3://backups/gitlab/11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar' \
	'/var/opt/gitlab/backups/'
sudo gitlab-ctl stop 'puma'
sudo gitlab-ctl stop 'sidekiq'
sudo GITLAB_ASSUME_YES=1 gitlab-backup restore BACKUP='11493107454_2018_04_25_10.6.4-ce'
sudo gitlab-ctl restart
sudo gitlab-rake 'gitlab:check' SANITIZE=true
sudo gitlab-rake 'gitlab:doctor:secrets'
sudo gitlab-rake 'gitlab:artifacts:check'
sudo gitlab-rake 'gitlab:lfs:check'
sudo gitlab-rake 'gitlab:uploads:check'

## Restore backups - end ------------- #

##
# Removal - start
##

sudo gitlab-ctl stop
sudo gitlab-ctl remove-accounts
sudo gitlab-ctl cleanse
sudo rm -rf '/etc/gitlab' '/opt/gitlab'
sudo dnf -y remove --noautoremove 'gitlab-ee'

## Removal - end --------------------- #

##
# Opensearch integration - start
##

# Estimate the required cluster size based on the total size of the repositories
sudo gitlab-rake 'gitlab:elastic:estimate_cluster_size'

# Estimate the required shard sizes for each index based on approximate database counts
# Does *not* include repository data (code, commits, and wikis)
sudo gitlab-rake 'gitlab:elastic:estimate_shard_sizes'

# Enable advanced search with Elasticsearch
sudo gitlab-rake 'gitlab:elastic:enable_search_with_elasticsearch'

# Disable advanced search with Elasticsearch
sudo gitlab-rake 'gitlab:elastic:disable_search_with_elasticsearch'

# Get information
sudo gitlab-rake 'gitlab:elastic:info'

# Index the entire instance
# Deletes all existing indices
sudo gitlab-rake 'gitlab:elastic:index'

# Index specific data
sudo gitlab-rake 'gitlab:elastic:index_epics'
sudo gitlab-rake 'gitlab:elastic:index_work_items'
sudo gitlab-rake 'gitlab:elastic:index_group_wikis'
sudo gitlab-rake 'gitlab:elastic:index_namespaces'
sudo gitlab-rake 'gitlab:elastic:index_projects'
sudo gitlab-rake 'gitlab:elastic:index_snippets'
sudo gitlab-rake 'gitlab:elastic:index_users'

# Delete indexes
sudo gitlab-rake gitlab:elastic:delete_index

# Get logs
tail -f '/var/log/gitlab/gitlab-rails/elasticsearch.log'

## Opensearch integration - end --------------------- #


# Check the included PostgreSQL version
sudo gitlab-psql -c 'SELECT version();'

# Check the status of batched background migrations
# Should the query return zero rows, all batched background migrations are complete
sudo gitlab-psql -c "SELECT job_class_name, table_name, column_name, job_arguments FROM batched_background_migrations WHERE status NOT IN(3, 6);"
