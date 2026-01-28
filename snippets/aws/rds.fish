#!/usr/bin/env fish

###
# DB instances' names are case-insensitive.
# Keep them here in lowercase.
###

aws rds describe-db-instances --db-instance-identifier 'some-test' --output 'yaml' \
	--query 'DBInstances[].{"DBInstanceStatus":DBInstanceStatus,"PendingModifiedValues":PendingModifiedValues}'

aws rds start-export-task \
	--export-task-identifier 'db-finalSnapshot-2024' \
	--source-arn 'arn:aws:rds:eu-west-1:012345678901:snapshot:db-prod-final-2024' \
	--s3-bucket-name 'backups' --s3-prefix 'rds' \
	--iam-role-arn 'arn:aws:iam::012345678901:role/CustomRdsS3Exporter' \
	--kms-key-id 'arn:aws:kms:eu-west-1:012345678901:key/abcdef01-2345-6789-abcd-ef0123456789'

# Change the storage type
aws rds modify-db-instance --db-instance-identifier 'instance-name' --storage-type 'gp3' --apply-immediately

# Show available upgrade target versions for a given DB engine version.
aws rds describe-db-engine-versions --engine 'postgres' --engine-version '13' \
	--query 'DBEngineVersions[*].ValidUpgradeTarget[*]'
aws rds describe-db-engine-versions --engine 'postgres' --engine-version '13.12' \
	--query 'DBEngineVersions[*].ValidUpgradeTarget[*].{AutoUpgrade:AutoUpgrade,EngineVersion:EngineVersion}[?AutoUpgrade==`true`][]'

# Start upgrading.
# Requires downtime.
aws rds modify-db-instance --db-instance-identifier 'my-db-instance' --engine-version '14.20' --apply-immediately
aws rds modify-db-instance --db-instance-identifier 'my-db-instance' \
	--engine-version '14.15' --allow-major-version-upgrade --no-apply-immediately

# Max 5 running at any given time, RDS cannot queue
echo {1..5} | xargs -p -n '1' -I '{}' aws rds start-export-task …

aws rds describe-export-tasks --query 'ExportTasks[].WarningMessage' --output 'json'

aws rds restore-db-instance-to-point-in-time \
	--source-db-instance-identifier 'awx' --target-db-instance-identifier 'awx-pitred' \
	--restore-time '2024-07-31T09:29:40+00:00' \
	--allocated-storage '20'
aws rds restore-db-instance-to-point-in-time \
	--source-db-instance-identifier 'awx' --target-db-instance-identifier 'awx-pitred' \
	--use-latest-restorable-time \
	--db-instance-class 'db.m8g.xlarge' \
	--no-multi-az --availability-zone 'eu-west-1a' \
	--db-subnet-group-name 'default' --no-publicly-accessible \
	--db-parameter-group-name 'postgresql14' --option-group-name 'default:postgres-14' \
	--storage-type 'gp3' \
	--no-dedicated-log-volume \
	--no-auto-minor-version-upgrade \
	--no-deletion-protection

aws rds restore-db-instance-from-db-snapshot \
	--db-instance-identifier 'awx-pitr-snapshot' \
	--db-snapshot-identifier 'rds:awx-2024-07-30-14-15'

aws rds delete-db-instance --db-instance-identifier 'awx'
aws rds delete-db-instance --db-instance-identifier 'awx-with-backups' \
	--skip-final-snapshot --delete-automated-backups --no-cli-pager

aws rds describe-db-parameters --db-parameter-group-name 'default.postgres15'
aws rds describe-db-parameters --db-parameter-group-name 'default.postgres15' \
	--query "Parameters[?ParameterName=='shared_preload_libraries']" --output 'table'
aws rds describe-db-parameters --db-parameter-group-name 'default.postgres15' \
	--query "Parameters[?ParameterName=='shared_preload_libraries'].ApplyMethod" --output 'text'
aws rds describe-db-parameters --db-parameter-group-name 'default.postgres15' \
	--output 'json' --query "Parameters[?ApplyType!='dynamic']"

aws rds create-db-snapshot --db-instance-identifier 'some-db-instance' --db-snapshot-identifier 'some-db-snapshot'

aws rds describe-db-instances --db-instance-identifier 'some-instance' \
	--query 'DBInstances[0].InstanceCreateTime' --output 'text'

aws rds describe-db-instances --db-instance-identifier 'some-db-instance' --output 'text' \
	--query 'DBInstances[0].Endpoint|join(`:`,[Address,to_string(Port)])'
aws rds describe-db-instances --db-instance-identifier 'some-db-instance' --output 'text' \
    --query '
		DBInstances[0]
		| join(``, [
			`postgresql://`,
			MasterUsername,
			`:`,
			`PASSWORD_PLACEHOLDER`,
			`@`,
			Endpoint.Address,
			`:`,
			to_string(Endpoint.Port),
			`/`,
			DBName || `postgres`
        ])
    '
