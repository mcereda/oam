#!/usr/bin/env fish

gpg-connect-agent reloadagent '/bye'

gpgconf --launch gpg-agent \
&& gpg-connect-agent updatestartuptty '/bye' \
&& set -x 'SSH_AUTH_SOCK' (gpgconf --list-dirs 'agent-ssh-socket') \
&& set -x 'GPG_TTY' (tty)

# Import private keys
gpg --decrypt --output - 'keys.asc.gpg' | gpg --import

# Trust keys
gpg --edit-key 'key.identifier@email.com'
# 'trust' > 5 (I trust ultimately) > save
gpg --list-secret-keys

# Get short key IDs for use in git
gpg --list-keys --keyid-format 'short' 'key.identifier@email.com' \
| grep -e "^pub\s*" | awk -F '/' '{print $2}' | awk '{print $1}'

# Export public keys
gpg --armor --export 'E455…50AB' | pbcopy
gpg --export-ssh-key 'E455…50AB' | pbcopy

# Sign a string
# Used by Gitea to prove one had the private key associated to a GPG public key
echo '1d64…9920' | gpg -a --default-key 'E455…50AB' --detach-sig

# Load identities in SSH
gpgconf --launch gpg-agent

# Encrypt files
find . -type f -not -name '*.gpg' \
	-path '*/values.*.y*ml' -path '*/secrets/*.*' \
	-exec gpg --batch --encrypt-files --yes -r "0123...CDEF" "{}" ';'
