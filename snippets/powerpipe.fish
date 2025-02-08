#!/usr/bin/env fish

brew install 'turbot/tap/powerpipe'

powerpipe --version
powerpipe start

powerpipe mod init
powerpipe mod list

powerpipe mod show local
powerpipe mod show 'steampipe-mod-aws-insights'
powerpipe mod show 'github.com/turbot/steampipe-mod-aws-insights@v0.21.0'

powerpipe mod install 'github.com/turbot/steampipe-mod-aws-thrifty'
powerpipe mod install 'github.com/turbot/steampipe-mod-aws-compliance@^0.92'
powerpipe mod install 'github.com/turbot/steampipe-mod-aws-compliance@^1'
powerpipe mod install --dry-run 'steampipe-mod-aws-compliance'
powerpipe mod install --dry-run 'github.com/turbot/steampipe-mod-aws-compliance@v0.93.0' 'github.com/turbot/steampipe-mod-aws-insights'

powerpipe mod update
powerpipe mod update 'github.com/turbot/steampipe-mod-aws-insights'

powerpipe benchmark list

powerpipe plugin install 'aws_compliance.benchmark.soc2'

powerpipe benchmark run 'aws_compliance.benchmark.soc2'
powerpipe benchmark run 'aws_compliance.benchmark.gdpr' --export 'json' --export 'nunit3'

powerpipe control list

powerpipe control run 'aws_compliance.control.cis_v150_3_3'
powerpipe control run 'aws_compliance.control.cis_v150_3_3' 'aws_compliance.control.vpc_vpn_tunnel_up'

powerpipe query list

powerpipe query run aws_insights.query.vpc_vpcs_for_vpc_subnet
powerpipe query run --output table aws_insights.query.vpc_vpcs_for_vpc_subnet
