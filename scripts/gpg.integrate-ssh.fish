#!/usr/bin/env fish

gpg-connect-agent updatestartuptty '/bye'
set -x 'SSH_AUTH_SOCK' (gpgconf --list-dirs 'agent-ssh-socket')
set -x 'GPG_TTY' (tty)
