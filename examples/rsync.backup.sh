#!/usr/bin/env bash

rsync /data/ nas.lan:/data/ \
	--archive --copy-links --protect-args --delete \
	--acls --xattrs --fake-super \
	--partial --append-verify \
	--compress --sparse --no-motd \
	--human-readable --no-inc-recursive --info="progress2" -vv \
	--exclude ".terraform*" --exclude "obsidian" \
	--backup --backup-dir "changes_$(date +'%F_%H-%m-%S')" --exclude "changes_*" \
| grep -Ev -e uptodate -e "/$"
