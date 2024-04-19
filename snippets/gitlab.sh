#!sh

sudo yum check-update
sudo yum info 'gitlab-ee'
sudo rpm -qa | grep 'gitlab-ee'
tmux new-session -A -s 'gitlab-upgrade' "sudo yum update 'gitlab-ee'"
