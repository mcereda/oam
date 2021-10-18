#!/usr/bin/bash
# https://www.dropbox.com/install-linux

[[ ${DEBUG} ]] && set -o xtrace

DROPBOX_retries=3
DROPBOX_script_download_path="/tmp/dropbox.py"
DROPBOX_script_installation_path="/usr/local/bin/dropbox"
DROPBOX_script_url="https://www.dropbox.com/download?dl=packages/dropbox.py"

echo "  downloading script…"
curl $DROPBOX_script_url \
	--continue-at - \
	--location \
   	--output $DROPBOX_script_download_path \
	--retry $DROPBOX_retries \
	--silent --show-error

echo "  installing script…"
sudo install $DROPBOX_script_download_path $DROPBOX_script_installation_path

[[ ${DEBUG} ]] && set +o xtrace
