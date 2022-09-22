#!/bin/zsh

: "${USER_EMAIL:?required but not set}"

: "${SIGNING_KEY:=$(\
	gpg --list-keys --keyid-format short "${USER_EMAIL}" \
	| grep --extended-regexp '^pub[[:blank:]]+[[:alnum:]]+/[[:alnum:]]+[[:blank:]].*\[[[:upper:]]*S[[:upper:]]*\]' \
	| awk '{print $2}' \
	| cut -d '/' -f 2 )}"
: "${SIGNING_KEY:?something went wrong}"

for REPOSITORY in $(find $@ -type d -name .git -exec dirname {} +)
do
	git -C "$REPOSITORY" config --local user.email "$USER_EMAIL"
	git -C "$REPOSITORY" config --local user.signingKey "$SIGNING_KEY"
	git -C "$REPOSITORY" config --local commit.gpgsign true
	git -C "$REPOSITORY" --no-pager config --list --show-origin
done
