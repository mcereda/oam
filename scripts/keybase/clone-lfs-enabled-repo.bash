#!/usr/bin/env bash

[[ $DEBUG ]] && set -x

: ${REPO_URL:?not set}
DESTINATION_DIR="${DESTINATION_DIR:-$PWD}"

git clone --no-checkout \
	"${REPO_URL}" \
	"${DESTINATION_DIR}/${REPO_URL##*/}"
cd "${DESTINATION_DIR}/${REPO_URL##*/}"
keybase git lfs-config
git checkout --force HEAD
cd -

[[ $DEBUG ]] && set +x
