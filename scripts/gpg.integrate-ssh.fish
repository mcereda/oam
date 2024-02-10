#!/usr/bin/env fish

gpg-connect-agent updatestartuptty /bye
set SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
export SSH_AUTH_SOCK
set GPG_TTY (tty)
export GPG_TTY
