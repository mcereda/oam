#!fish

gpg-connect-agent reloadagent '/bye'

gpgconf --launch gpg-agent \
&& gpg-connect-agent updatestartuptty '/bye' \
&& set -x 'SSH_AUTH_SOCK' (gpgconf --list-dirs 'agent-ssh-socket') \
&& set -x 'GPG_TTY' (tty)

# Export public keys.
gpg --armor --export 'E455…50AB' | pbcopy
gpg --export-ssh-key 'E455…50AB' | pbcopy

# Load identities in SSH.
gpgconf --launch gpg-agent
