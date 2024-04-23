#!fish

gpg-connect-agent reloadagent '/bye'

gpgconf --launch gpg-agent \
&& gpg-connect-agent updatestartuptty '/bye' \
&& set -x 'SSH_AUTH_SOCK' (gpgconf --list-dirs 'agent-ssh-socket') \
&& set -x 'GPG_TTY' (tty)
