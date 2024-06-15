#!/usr/bin/env sh

rsync -AELPXansvvz --append-verify --delete \
	--fake-super --no-i-r --no-motd --exclude '@eaDir' --exclude "changes_*" \
	"synology.lan:/volume1/vault/" \
	"./" \
| grep -Ev -e uptodate -e "/$"

rsync -vv --append-verify --delete --executability --partial --progress --dry-run  \
	--archive --acls --xattrs --human-readable --sparse --copy-links --preallocate \
	--fake-super --no-inc-recursive --no-motd --exclude '@eaDir' --compress --secluded-args \
	--backup --backup-dir="changes_$(date +'%F_%H-%m-%S')" --exclude "changes_*" \
	"synology.lan:/volume1/vault/" \
	"./"
