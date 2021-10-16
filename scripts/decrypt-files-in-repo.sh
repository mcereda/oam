#!/usr/bin/env sh

TOP_LEVEL="$(git rev-parse --show-toplevel)"

echo "Decrypting files…"

find "${TOP_LEVEL}/${1}" \
	-type f \
	-name '*.gpg'  \
	-exec gpg --batch --decrypt-files --yes "{}" +

echo "Files decrypted"
