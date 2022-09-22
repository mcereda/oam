#!/usr/bin/env bash

# Sources:
# - https://www.gnupg.org/documentation/manuals/gnupg/Unattended-GPG-key-generation.html

: "${REAL_NAME:?required but not set}"
: "${PASSPHRASE:?required but not set}"

: "${KEY_TYPE:=rsa}"
: "${KEY_LENGTH:=4096}"
: "${EXPIRE_DATE:=5y}"

for EMAIL in $@
do
	if gpg --list-secret-keys "$EMAIL" >/dev/null 2>&1
	then
		echo "gpg key for ${EMAIL} already exists" >&2
	else
		gpg --batch --generate-key <<-EOF
			%echo generating key for $EMAIL
			Key-Type: $KEY_TYPE
			Key-Length: $KEY_LENGTH
			Name-Real: $REAL_NAME
			Name-Email: $EMAIL
			Expire-Date: $EXPIRE_DATE
			Passphrase: $PASSPHRASE
			%commit
			%echo done
		EOF
	fi
done
