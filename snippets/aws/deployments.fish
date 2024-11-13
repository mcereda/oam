#!/usr/bin/env fish

aws deploy list-applications

aws deploy list-deployment-groups --application-name 'Evidently'
aws deploy get-deployment-group --application-name 'Evidently' --deployment-group-name 'production' --output 'json' | pbcopy

diff -y -W 200 \
(aws deploy get-deployment-group --application-name 'Evidently' --deployment-group-name 'staging' --output json | psub) \
(aws deploy get-deployment-group --application-name 'Evidently' --deployment-group-name 'production' --output 'json' | psub)

aws deploy create-deployment --application-name 'Evidently' --deployment-group-name 'staging' \
	--description 'This is Evidently a deployment (☞ﾟ∀ﾟ)☞' \
	--s3-location 'bundleType=zip,bucket=deployments-bucket,key=evidently-master-staging.zip'

aws deploy list-deployments --application-name 'Evidently' --deployment-group-name 'production' \
	--include-only-statuses 'Created' 'Queued' 'InProgress'
aws deploy get-deployment --deployment-id 'd-JNCR4R7F8'
