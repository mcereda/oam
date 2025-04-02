#!/usr/bin/env fish

# Link secrets
gopass ln 'stackexchange.com/me@example.org' 'stackoverflow.com/me@example.org'

# List templates
gopass templates

# Create templates
gopass templates edit 'path/to/dir'
gopass templates create 'path/to/dir'
gopass templates new 'path/to/dir'

# Show templates
gopass templates show 'path/to/dir'
gopass templates cat 'path/to/dir'

# Remove templates
gopass templates remove 'path/to/dir'
gopass templates rm 'path/to/dir'
