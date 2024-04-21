#!sh

# Updated config template available at
# https://gitlab.com/gitlab-org/omnibus-gitlab/blame/master/files/gitlab-config-template/gitlab.rb.template

# Local template (corresponding to the installed version) available at '/opt/gitlab/etc/gitlab.rb.template'

sudo dnf -y install 'ruby' 'vim'
sudo vim '/etc/gitlab/gitlab.rb'
sudo ruby -c '/etc/gitlab/gitlab.rb'
sudo gitlab-ctl show-config
sudo gitlab-ctl reconfigure
