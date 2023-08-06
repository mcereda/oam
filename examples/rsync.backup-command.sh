#!/usr/bin/env bash

# Sync directories from a Linux source to a Linux destination.
# Expand symlink at the source to their referred files.
# Assumes the same owner and group at both hosts.
rsync 'data/' 'nas.lan:data/' \
	--secluded-args --no-inc-recursive \
	--archive --copy-links --acls --xattrs --times --atimes --crtimes \
	--partial --append-verify --sparse \
	--human-readable --info='progress2' \
	--delete --backup --backup-dir "changes_$(date +'%F_%H-%M-%S')" --exclude "changes_*"
rsync 'data/' 'nas.lan:data/' \
	-abhstALNSUX --no-i-r \
	--partial --append-verify \
	--info='progress2' \
	--delete --backup-dir "changes_$(date +'%F_%H-%M-%S')" --exclude "changes_*"


# Sync directories from a Linux source to a Synology NAS.
# The above one, just modified to be accepted from those systems.
rsync 'data/' 'synology.lan:/volume1/data/' \
	--secluded-args --no-inc-recursive \
	--archive --copy-links --acls --xattrs \
	--partial --append-verify --sparse \
	--human-readable --info='progress2' \
	--delete --backup --backup-dir "changes_$(date +'%F_%H-%M-%S')" --exclude "changes_*" \
	--no-motd --fake-super --super --chown='user:users' \
	--exclude={'@eaDir','#recycle'}
rsync 'data/' 'synology.lan:/volume1/data/' \
	-abhsALSX --no-i-r \
	--partial --append-verify \
	--info='progress2' \
	--delete --backup-dir "changes_$(date +'%F_%H-%M-%S')" --exclude "changes_*" \
	--no-motd --fake-super --super --chown='user:users' \
	--exclude={'@eaDir','#recycle'}


# Use the '.rsync-filter' file.
# The filter file excludes files from the source, but does nothing for the ones
# on the remote side. To exclude them too, explicitly use the `--exclude` option.
$ rsync … -F
