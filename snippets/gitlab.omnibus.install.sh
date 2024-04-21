#!sh

# Instance OS: AmazonLinux 2023
# Instance size: t4g.xlarge
# Source: https://about.gitlab.com/install/#amazonlinux-2023

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

xdg-open 'http://ip-172-31-73-256.eu-south-2.compute.internal'
