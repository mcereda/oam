#!/usr/bin/env bash

set -e

sudo apt update
sudo apt install --assume-yes boinc-client boinctui

BAM="http://bam.boincstats.com/"

ACCT_MGR_URL="${ACCT_MGR_URL:-$BAM}"
ACCT_MGR_USERNAME="${ACCT_MGR_USERNAME}"
ACCT_MGR_PASSWORD="${ACCT_MGR_PASSWORD}"

boinccmd --acct_mgr attach "${ACCT_MGR_URL}" "${ACCT_MGR_USERNAME}" "${ACCT_MGR_PASSWORD}"

## /var/lib/boinc/cc_config.xml
# …
#     <allow_remote_gui_rpc>1</allow_remote_gui_rpc>   # <-- add this
#   </log_flags>
# </cc_config>
##

## /var/lib/boinc/remote_hosts.cfg
## network addresses do not work, only single hosts
# 192.168.0.190   # my-laptop
##
