#!/usr/bin/env fish

brew install 'turbot/tap/steampipe'

steampipe --version
steampipe service status
steampipe service start
steampipe service restart
steampipe service stop

steampipe plugin list
steampipe plugin install 'steampipe' 'aws@^0' 'theapsgroup/gitlab@v0.6.0'
steampipe plugin install 'steampipe' 'aws^0' 'theapsgroup/gitlab@v0.6.0'
steampipe plugin install 'steampipe' 'aws^0.130' 'theapsgroup/gitlab@v0.6.0'
steampipe plugin install 'steampipe' 'aws@^0.130' 'theapsgroup/gitlab@v0.6.0'
steampipe plugin update --all
steampipe plugin update 'steampipe' 'aws'
steampipe plugin uninstall 'hub.steampipe.io/plugins/turbot/aws@^0.130'
steampipe plugin uninstall 'steampipe' 'theapsgroup/gitlab@0.6.0' 'hub.steampipe.io/plugins/turbot/aws@^0'

powerpipe mod install 'github.com/turbot/steampipe-mod-aws-compliance@^0.92'
powerpipe mod install 'github.com/turbot/steampipe-mod-aws-compliance@^1'
powerpipe mod install --dry-run 'github.com/turbot/steampipe-mod-aws-compliance'
powerpipe mod show 'steampipe-mod-aws-insights'
powerpipe mod show 'github.com/turbot/steampipe-mod-aws-insights@v0.21.0'
powerpipe mod show github.com/turbot/steampipe-mod-aws-insights@0.21.0
powerpipe mod show github.com/turbot/steampipe-mod-aws-insights

steampipe check all
steampipe check mod
steampipe check 'benchmark.cis_v130'

steampipe query list

# Start interactive sessions
steampipe query

# List AWS IAM users and their group
steampipe query 'select name from aws_iam_role'
steampipe query "SELECT iam_user ->> 'UserName' as User, name as Group FROM aws_iam_group CROSS JOIN jsonb_array_elements(users) as iam_user"
