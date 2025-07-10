#!/usr/bin/env sh

# Quote whatever is not a space
sed -E 's|([[:graph:]]+)|"\1"|g'

# Delete 5 lines after a pattern (including the line with the pattern)
sed '/pattern/,+5d' 'file.txt'
