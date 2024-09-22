#!/usr/bin/env sh

# Quote whatever is not a space.
sed -E 's|([[:graph:]]+)|"\1"|g'
