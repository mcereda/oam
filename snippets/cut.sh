#!/usr/bin/env sh

# limit strings to some length
echo 'some string longer than 20 characters' | cut -c '1-20'
