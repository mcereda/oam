#!/usr/bin/env fish

# Show information about the elasticsearch cluster for advanced search
gitlab-rake 'gitlab:elastic:info'

# List pending migrations
gitlab-rake gitlab:elastic:list_pending_migrations


# List group wiki pages
# `glab`` does not support group wikis.
gitlab -o 'json' group-wiki list --group-id '42'

# Get specific group wiki pages content by slug.
gitlab -o 'json' group-wiki get --group-id '42' --slug 'runbooks/deploy-process' | jq -r '.content'
