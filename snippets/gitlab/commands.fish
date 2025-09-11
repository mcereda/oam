#!/usr/bin/env fish

# Show information about the elasticsearch cluster for advanced search
gitlab-rake 'gitlab:elastic:info'

# List pending migrations
gitlab-rake gitlab:elastic:list_pending_migrations
