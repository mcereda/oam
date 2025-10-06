#!/usr/bin/env fish

# List Slack workspaces
aws chatbot describe-slack-workspaces
aws chatbot describe-slack-workspaces --query 'SlackWorkspaces'

# Show Slack channel configurations
aws chatbot describe-slack-channel-configurations
aws chatbot describe-slack-channel-configurations --query 'SlackChannelConfigurations'
