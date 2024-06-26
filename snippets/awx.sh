#!/usr/bin/env sh

# List all available endpoints
curl -fs 'https://awx.company.com/api/v2/' | jq '.' -

# list all jobs
curl -fs --user 'admin:password' 'https://awx.company.com/api/v2/job_templates/' | jq '.' -
curl -fs 'https://awx.company.com/api/v2/job_templates/' | jq '.' -
