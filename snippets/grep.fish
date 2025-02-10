#!/usr/bin/env fish

# Check unwanted data
# Show file name and line number
! grep -EHinr -e 'some' -e 'regexp' * || ( echo 'unwanted data found' >&2 && false )
