#!/usr/bin/env sh

# List dashboards
curl -sS 'http://grafana:3000/api/search' -H 'Authorization: Basic YWRtaW46YWRtaW4='
curl -sS 'https://g-0123456789.grafana-workspace.eu-west-1.amazonaws.com/api/dashboards/uid/abcdefghijklmn' \
	-H 'Authorization: Bearer glsa_0123456789AbcdEfghIjklMnopQrstUv_0123abcd'

# Get dashboards' json definition
curl -sS 'https://g-0123456789.grafana-workspace.eu-west-1.amazonaws.com/api/dashboards/uid/abcdefghijklmn' \
	-H 'Authorization: Bearer glsa_0123456789AbcdEfghIjklMnopQrstUv_0123abcd'

# Export all existing dashboards by ID
curl -sS 'http://grafana:3000/api/search' -H 'Authorization: Basic YWRtaW46YWRtaW4=' \
| jq -r '.[].uid' - \
| parallel " \
	curl -sS 'http://grafana:3000/api/dashboards/uid/{}' -H 'Authorization: Basic YWRtaW46YWRtaW4=' \
	> '{}.json' \
"

# Get the UID of all dashboards using specific data sources
curl -Ss 'https://g-0123456789.grafana-workspace.eu-west-1.amazonaws.com/api/search' \
	-H 'Authorization: Bearer glsa_0123456789AbcdEfghIjklMnopQrstUv_0123abcd' \
| jq -r '.[].uid' \
| parallel " \
	curl -Ss 'https://g-0123456789.grafana-workspace.eu-west-1.amazonaws.com/api/dashboards/uid/{}' \
		-H 'Authorization: Bearer glsa_0123456789AbcdEfghIjklMnopQrstUv_0123abcd' \
" \
| jq -rs '
	.[].dashboard
	| select(
		(.panels[]? | if .datasource|type == "string" then .datasource else .datasource?.uid end) == "abcdefghi"
	).uid
' - \
| sort -u
