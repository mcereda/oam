#!/usr/bin/env sh

function dropbox-install {
	# https://www.dropbox.com/install-linux
	[[ ${DEBUG} ]] && set -o xtrace

	DROPBOX_archive="/tmp/dropbox_daemon.tar.gz"
	DROPBOX_retries="3"
	DROPBOX_url="http://www.getdropbox.com/download?plat=lnx.x86_64"

	# download daemon
	echo "  downloading archive…"
	curl $DROPBOX_url \
		--continue-at - \
		--location \
    	--output $DROPBOX_archive \
		--retry $DROPBOX_retries \
		--silent --show-error

	# install daemon
	[[ -d "${HOME}/.dropbox-dist" ]] && echo "  removing old executables…" && rm -r "${HOME}/.dropbox-dist"
	echo "  unarchiving tarball…"
	tar zxf $DROPBOX_archive -C $HOME

	# cleaning
	rm $DROPBOX_archive

	[[ ${DEBUG} ]] && set +o xtrace
}

if [ ! -f start-multiple-instances.sh ]
then
	echo "[ERROR] Dropbox multi-instances start script not usable. Aborting."
	exit 1
fi

if [ ! -d ${HOME}/.dropbox-dist ]
then
	echo "[WARNING] Default Dropbox dist directory not found."
	echo "[WARNING] Downloading and installing in the default directory."
else
	rm -r ${HOME}/.dropbox-dist
fi

echo "[NOTICE] Stopping all processes using the current version of Dropbox."
killall -I dropbox

dropbox-install

echo "[NOTICE] Restarting Dropbox daemons for all acounts."
./start-multiple-instances.sh
