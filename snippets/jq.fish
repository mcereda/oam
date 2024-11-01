#!/usr/bin/env fish

# Update values of keys
jq '.dependencies."@pulumi/aws" |= "6.57.0"' 'package.json' | sponge 'package.json'
