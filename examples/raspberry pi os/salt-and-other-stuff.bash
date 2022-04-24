!#/usr/bin/env bash

sudo apt update
sudo apt upgrade
sudo apt install salt-master salt-minion
sudo chown -R salt:salt /var/lib/salt
sudo gpasswd -a pi salt
passwd
sudo hostnamectl set-hostname pi4.lan
sudo vim.tiny /etc/salt/minion.d/master.conf
sudo rm /etc/salt/minion_id
sudo shutdown -r now
sudo salt-key --list all
sudo timedatectl set-timezone Europe/Dublin
sudo timedatectl status
sudo salt-key --list all
sudo salt-key --accept pi4.lan
sudo systemctl enable --now ssh.service
sudo curl -fsSL https://get.docker.com | sh -
sudo usermod -aG docker ${USER}
docker run --rm --name test hello-world
docker rmi hello-world
sudo apt install docker-compose
mkdir -p docker/boinc-client docker/pi-hole docker/nextcloud
cd docker/boinc-client
vim.tiny docker-compose.yml
docker-compose up -d
docker-compose logs --follow
cd ../pi-hole
vim.tiny docker-compose.yml
docker-compose up -d
docker-compose logs -f
sudo vim.tiny /etc/locale.gen
sudo locale-gen
sudo localectl set-locale LANG=en_IE.utf8 LANGUAGE=en_IE.utf8
mkdir -p repositories/private
