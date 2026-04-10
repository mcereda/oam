#!/usr/bin/env fish

# Manage the GPG Agent
gpgconf --launch 'gpg-agent'
gpgconf --reload 'gpg-agent'
gpgconf --kill 'gpg-agent'
gpg-connect-agent updatestartuptty '/bye'
gpg-connect-agent reloadagent '/bye'

# Enable SSH and Pinentry integration
set -x 'SSH_AUTH_SOCK' (gpgconf --list-dirs 'agent-ssh-socket')
set -x 'GPG_TTY' (tty)

# Reset GPG+SSH integration
gpgconf --launch gpg-agent \
&& gpg-connect-agent updatestartuptty '/bye' \
&& set -x 'SSH_AUTH_SOCK' (gpgconf --list-dirs 'agent-ssh-socket') \
&& set -x 'GPG_TTY' (tty)

# List keys
gpg --list-keys 'jd@example.org'
gpg --list-keys --keyid-format 'short'
gpg --list-secret-keys --with-keygrip --keyid-format '0xlong'

# Generate keys
gpg --full-generate-key
gpg --expert --full-generate-key
gpg --batch --generate-key <<-'EOF'
	%no-protection
	Key-Type: eddsa
	Key-Curve: ed25519
	Name-Real: John Dorian
	Name-Email: jd@example.org
	Expire-Date: 0
	%commit
EOF

# Import keys
gpg --import 'keys.asc'
gpg --decrypt --output - 'keys.asc.gpg' | gpg --import


# Export keys
gpg --armor --export 'jd@example.org' > 'path/to/public-key.asc'
gpg --armor --export-secret-keys "E455…50AB" > 'path/to/secret-key.asc'
gpg --export-ssh-key 'E455…50AB' | pbcopy

# Save revocation certificates
cp "$HOME/.gnupg/openpgp-revocs.d/3CD2…FA2C.rev" 'path/to/revocation-cert.rev'

# Delete keys
gpg --delete-secret-key 'jd@example.org'
gpg --delete-key 'jd@example.org'
gpg --batch --yes --delete-secret-and-public-key '3CD2…FA2C'

# Trust keys
gpg --edit-key 'jd@example.org'
# > 'trust' > 5 (I trust ultimately) > quit

# Manage trust settings
gpg --import-ownertrust 'otrust.txt'
gpg --export-ownertrust > 'otrust.txt'

# Key management
gpg --fingerprint 'jd@example.org'
gpg --quick-set-expire '3CD2…FA2C' '1y'
gpg --quick-set-expire '3CD2…FA2C' '2y' '*'
gpg --passwd '3CD2…FA2C'
gpg --change-passphrase --dry-run 'jd@example.org'
gpg --generate-revocation -ao 'revoke.cert' '3CD2…FA2C'

# Get the short ID of the signing key for git
gpg --list-keys --keyid-format 'short' 'jd@example.org' \
| grep -e "^pub\s*" | awk -F '/' '{print $2}' | awk '{print $1}'
gpg --list-keys --keyid-format 'short' 'jd@example.org' \
| grep -E '^pub\s.*\[.*S.*\]' | awk '{print $2}' | cut -d '/' -f 2

# Encrypt files
gpg -o 'file.out.gpg' -r 'jd@example.org' -e 'file.in'
gpg --symmetric --s2k-cipher-algo 'AES256' 'file.in'
gpg -e -r 'jd@example.org' -r 'E455…50AB' 'file.in'
find . -type f -name 'secret.txt' \
	-exec gpg --batch --yes --encrypt-files -r 'jd@example.org' {} ';'
find . -type f -not -name '*.gpg' \
	-path '*/values.*.y*ml' -path '*/secrets/*.*' \
	-exec gpg --batch --encrypt-files --yes -r "0123...CDEF" "{}" ';'

# Decrypt files
gpg -o 'file.out' --decrypt 'file.in.gpg'
find . -type f -name '*.gpg' -exec gpg --decrypt-files {} +

# Encrypt/decrypt directories
gpgtar -o 'dir.tar.gpg' -c 'input/dir'
gpgtar -o 'dir' -d 'dir.tar.gpg'

# Sign data
gpg --detach-sign 'file'
# Use this to prove one had the private key associated to a GPG public key
echo '1d64…9920' | gpg -a --default-key 'E455…50AB' --detach-sign

# Only get the base64 armored string in the key
# -e '/^-----/d' removes the header and footer
# -e '/^=/d' removes the base64 checksum at the bottom
# -e '/^$/d' removes empty lines
gpg --armor --export 'jd@example.org' | sed -e '/^-----/d' -e '/^=/d' -e '/^$/d'
