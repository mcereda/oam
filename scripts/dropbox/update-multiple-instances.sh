#!/usr/bin/env sh

function dropbox-install {
    export DROPBOX_archive="dropbox_daemon.tar.gz"
    export DROPBOX_retries="3"
    export DROPBOX_url="http://www.getdropbox.com/download?plat=lnx.x86_64"

    # download daemon
    echo "  downloading archive…"
    curl -C - -o $DROPBOX_archive --retry $DROPBOX_retries -S -L $DROPBOX_url

    # install daemon
    echo "  unarchiving tarball…"
    tar zxf $DROPBOX_archive -C $HOME

    # cleaning
    rm $DROPBOX_archive
}

if [ ! -f start-multiple-instances.sh ]
then
    echo "[ERROR] Dropbox multi-instances start script not usable. Aborrting."
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

echo "[NOTICE] Faccio ripartire il processo per ogni account"
./start-multiple-instances.sh
