#!/usr/bin/env fish

# Connect to PeerDB server in SQL mode
psql 'port=9900 host=localhost password=peerdb'

# List peers
curl -fsS --url 'http://localhost:3000/api/v1/peers/list' \
	-H "Authorization: Basic $(gopass show -o 'peerdb/instance' | xargs printf '%s' ':' | base64)"
psql 'port=9900 host=localhost password=peerdb' \
	-c "SELECT id, name, type FROM peers;"

# Create peers
# postgres: peer.type=3|'POSTGRES' + postgres_config={…}
# clickhouse: peer.type=8 + clickhouse_config={…}
# kafka: peer.type=9 + kafka_config={…}
curl -fsS --url 'http://localhost:3000/api/v1/peers/create' -X 'POST' \
	-H "Authorization: Basic $(gopass show -o 'peerdb/instance' | xargs printf '%s' ':' | base64)" \
	-H 'Content-Type: application/json' \
	-d "{
		\"peer\": {
			\"name\": \"some_pg_peer\",
			\"type\": \"POSTGRES\",
			\"postgres_config\": {
				\"host\": \"localhost\",
				\"port\": 5432,
				\"user\": \"peerdb\",
				\"password\": \"$(gopass show -o 'peerdb/db-user')\",
				\"database\": \"sales\"
			}
		}
	}"
psql 'port=9900 host=localhost password=peerdb' \
	-c "CREATE PEER some_pg_peer FROM POSTGRES WITH (
		host = 'localhost',
		port = '5432',
		user = 'peerdb',
		password = '$(gopass show -o 'peerdb/db-user')',
		database = 'sales'
	);"

# Update peers
# Reuse the command for creation but add 'allow_update: true' to the data
curl -fsS --url 'http://localhost:3000/api/v1/peers/create' -X 'POST' … \
	-d "{
		\"peer\": { … },
		allow_update: true
	}"

# List mirrors
curl -fsS --url 'http://localhost:3000/api/v1/mirrors/list' \
	-H "Authorization: Basic $(gopass show -o 'peerdb/instance' | xargs printf '%s' ':' | base64)" \
| jq '.mirrors[]' -

# Get mirrors' status
curl -fsS 'http://localhost:3000/api/v1/mirrors/status' -X 'POST' \
	-H "Authorization: Basic $(gopass show -o 'peerdb/instance' | xargs printf '%s' ':' | base64)" \
	-H 'Content-Type: application/json' \
	-d '{ "flowJobName": "testing_bq_2" }'

# Get mirrors' configuration
curl -fsS 'http://localhost:3000/api/v1/mirrors/status' -X 'POST' \
	-H "Authorization: Basic $(gopass show -o 'peerdb/instance' | xargs printf '%s' ':' | base64)" \
	-H 'Content-Type: application/json' \
	-d '{
		"flowJobName": "testing_bq_2",
		"includeFlowInfo": true
	}' \
| jq '.cdcStatus.config' -

# Create mirrors
curl -fsS 'http://localhost:3000/api/v1/flows/cdc/create' -X 'POST' \
	-H "Authorization: Basic $(gopass show -o 'peerdb/instance' | xargs printf '%s' ':' | base64)" \
	-H 'Content-Type: application/json' \
	-d '{
		"connection_configs": {
			"flow_job_name": "testing_bq_2",
			"source_name": "some_pg_peer",
			"destination_name": "some_other_pg_peer",
			"table_mappings": [
				{
					"source_table_identifier": "public.users",
					"destination_table_identifier": "users_api"
				},
				{
					"source_table_identifier": "public.payments",
					"destination_table_identifier": "payments_api"
				},
				{
					"source_table_identifier": "public.optional_ordering_key",
					"destination_table_identifier": "optional_ordering_key",
					"columns": [
						{
							"name": "id",
							"ordering": 1
						},
						{
							"name": "created_at",
							"ordering": 2
						}
					]
				},
			],
			"do_initial_snapshot": true
		}
	}'

# Show alerts' configuration
curl -fsS --url 'http://localhost:3000/api/v1/alerts/config' \
	-H "Authorization: Basic $(gopass show -o 'peerdb/instance' | xargs printf '%s' ':' | base64)" \
| jq '.configs[]' -

# Create alerts
# 'service_config' seems must be a string
curl -fsS --url 'http://localhost:3000/api/v1/alerts/config' -X 'POST' \
	-H "Authorization: Basic $(gopass show -o 'peerdb/instance' | xargs printf '%s' ':' | base64)" \
	-H 'Content-Type: application/json' \
	-d '{
		"config": {
			"id": -1,
			"service_type": "slack",
			"service_config": "{\"slot_lag_mb_alert_threshold\":15000,\"open_connections_alert_threshold\":20,\"auth_token\":\"xoxb-012345678901-0123456789012-1234ABcdEFGhijKLMnopQRST\",\"channel_ids\":[\"C01K23X4567\"]}",
			"alert_for_mirrors": [
				"odoo_postgres_to_snowflake",
				"product_korea_postgres_to_snowflake",
				"product_zimbabwe_postgres_to_snowflake"
			]
		}
	}'

# Others
curl -fsS 'http://localhost:3000/api/v1/dynamic_settings' \
	-H "Authorization: Basic $(gopass show -o 'peerdb/instance' | xargs printf '%s' ':' | base64)" \
| jq '.settings[]' -
curl -fsS --url 'http://localhost:3000/api/v1/scripts/-1' \
	-H "Authorization: Basic $(gopass show -o 'peerdb/instance' | xargs printf '%s' ':' | base64)" \
| jq '.scripts[]' -
