#!sh

sudo vim '/etc/gitlab/gitlab.rb'
sudo gitlab-ctl check-config
sudo gitlab-ctl diff-config   # if one really needs to
sudo gitlab-ctl reconfigure
