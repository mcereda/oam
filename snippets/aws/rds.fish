#!/usr/bin/env fish

###
# DB instances' names are case-insensitive.
# Keep them here in lowercase.
###

# Check status and pending changes.
aws rds describe-db-instances --db-instance-identifier 'production-db' --output 'yaml' \
	--query 'DBInstances[].{"DBInstanceStatus":DBInstanceStatus,"PendingModifiedValues":PendingModifiedValues}'

# Get creation time.
aws rds describe-db-instances --db-instance-identifier 'production-db' \
	--query 'DBInstances[0].InstanceCreateTime' --output 'text'

# Get connection URLs.
aws rds describe-db-instances --db-instance-identifier 'production-db' --output 'text' \
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

# Wait for instances to become available.
aws rds wait db-instance-available --db-instance-identifier 'production-db'
aws rds wait db-instance-available \
	--filters 'Name=db-instance-id,Values=prod-db,prod-db-rr-eng,prod-db-rr-others'


# Export a snapshot to S3.
# Max 5 running at any given time; RDS cannot queue them.
aws rds start-export-task \
	--export-task-identifier 'db-finalSnapshot-2024' \
	--source-arn 'arn:aws:rds:eu-west-1:012345678901:snapshot:db-prod-final-2024' \
	--s3-bucket-name 'backups' --s3-prefix 'rds' \
	--iam-role-arn 'arn:aws:iam::012345678901:role/CustomRdsS3Exporter' \
	--kms-key-id 'arn:aws:kms:eu-west-1:012345678901:key/abcdef01-2345-6789-abcd-ef0123456789'
aws rds describe-export-tasks --query 'ExportTasks[].WarningMessage' --output 'json'
aws rds cancel-export-task --export-task-identifier 'db-finalSnapshot-2024'
echo {1..5} | xargs -p -n '1' -I '{}' aws rds start-export-task …


# Inspect parameter groups.
aws rds describe-db-parameters --db-parameter-group-name 'default.postgres15' \
	--query "Parameters[?ParameterName=='shared_preload_libraries']" --output 'table'
aws rds describe-db-parameters --db-parameter-group-name 'default.postgres15' \
	--output 'json' --query "Parameters[?ApplyType!='dynamic']"

# Create and configure a parameter group for pg_transport.
aws rds create-db-parameter-group --db-parameter-group-name 'pg15-source-transport-group' \
	--db-parameter-group-family 'postgres15' --description 'Parameter group with transport parameters enabled'
aws rds modify-db-parameter-group --db-parameter-group-name 'pg15-source-transport-group' \
	--parameters \
		'ParameterName=pg_transport.num_workers,ParameterValue=4,ApplyMethod=pending-reboot' \
		'ParameterName=pg_transport.timing,ParameterValue=1,ApplyMethod=pending-reboot' \
		'ParameterName=pg_transport.work_mem,ParameterValue=131072,ApplyMethod=pending-reboot' \
		'ParameterName=shared_preload_libraries,ParameterValue="pg_stat_statements,pg_transport",ApplyMethod=pending-reboot' \
		'ParameterName=max_worker_processes,ParameterValue=24,ApplyMethod=pending-reboot'


# Show available upgrade paths for PostgreSQL 13.
aws rds describe-db-engine-versions --engine 'postgres' --engine-version '13.12' \
	--query 'DBEngineVersions[*].ValidUpgradeTarget[*].{AutoUpgrade:AutoUpgrade,EngineVersion:EngineVersion}[?AutoUpgrade==`true`][]'

# Upgrade engine version (minor).
aws rds modify-db-instance --db-instance-identifier 'production-db' \
	--engine-version '14.20' --apply-immediately
# Upgrade engine version (major). Requires downtime.
aws rds modify-db-instance --db-instance-identifier 'production-db' \
	--engine-version '14.15' --allow-major-version-upgrade --no-apply-immediately

# Change storage type.
aws rds modify-db-instance --db-instance-identifier 'redash' --storage-type 'gp3' --apply-immediately

# Change instance class.
aws rds modify-db-instance --db-instance-identifier 'redash' --db-instance-class 'db.t4g.medium' --apply-immediately

# Reset credentials.
aws rds modify-db-instance --db-instance-identifier 'production-db' \
	--master-user-password 'new-password' --apply-immediately

# Rename an instance.
aws rds modify-db-instance --apply-immediately \
	--db-instance-identifier 'current-instance-id' \
	--new-db-instance-identifier 'desired-instance-id'

# Disable backups.
aws rds modify-db-instance --db-instance-identifier 'awx-pitred' \
	--backup-retention-period 0 --apply-immediately


# Restore to a specific point in time.
aws rds restore-db-instance-to-point-in-time \
	--source-db-instance-identifier 'awx' --target-db-instance-identifier 'awx-pitred' \
	--restore-time '2024-07-31T09:29:40+00:00'
# … with explicit instance configuration.
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
	--backup-retention-period '0' \
	--no-deletion-protection

# Restore instances from snapshot.
aws rds restore-db-instance-from-db-snapshot \
	--db-instance-identifier 'awx-pitr-snapshot' \
	--db-snapshot-identifier 'rds:awx-2024-07-30-14-15'


# Delete instances.
aws rds delete-db-instance --db-instance-identifier 'awx'
aws rds delete-db-instance --db-instance-identifier 'awx-with-backups' \
	--skip-final-snapshot --delete-automated-backups --no-cli-pager
