#!/usr/bin/env bash

set -euo 'pipefail'

ERROR_GENERIC=1
ERROR_REQUIRED_TOOL_MISSING=2

pre_flight() {
    REQUIRED_TOOLS=(
        'xargs'
		'…'
    )
    for TOOL in ${REQUIRED_TOOLS[@]}
    do
        if ! ( which "$TOOL" > '/dev/null' )
        then
            echo -e "missing required tool: $TOOL" >&2
            exit $ERROR_REQUIRED_TOOL_MISSING
        fi
    done
}

pre_flight
# …
