#!/usr/bin/env fish

# Check unwanted data
# Show file name and line number
! grep -EHinr -e 'some' -e 'regexp' * || ( echo 'unwanted data found' >&2 && false )

# Only print matching lines
grep -Eo 'CONFIG_[A-Z0-9_]+' 'kernel_config'

# Print matching lines with context
grep -E --after-context=1 '[[:digit:]]+ VIEW'
