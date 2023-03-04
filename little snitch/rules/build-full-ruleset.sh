#!/usr/bin/env bash

WORKDIR=$(dirname "$0")

# Pre-flight checks
# -----------------

# Check files are readable JSON files.
PRE_FLIGHT_CHECKS_RESULT=0
for FILE in "${WORKDIR}/parts/"*.lsrules
do
	if ! jq '.' "$FILE" > /dev/null
	then
		echo "$FILE"
		PRE_FLIGHT_CHECKS_RESULT=1
	fi
done

[[ "$PRE_FLIGHT_CHECKS_RESULT" -ne 0 ]] && exit "$PRE_FLIGHT_CHECKS_RESULT"

# Actual work
# -----------

jq --indent 4 -M \
	'.rules=([inputs.rules]|flatten)' \
	"${WORKDIR}/all.lsrules" \
	"${WORKDIR}/parts/"*.lsrules \
| sponge "${WORKDIR}/all.lsrules"
