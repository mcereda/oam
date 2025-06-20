#!/usr/bin/env sh

find "$HOME/bin" -type 'l' \( -name "pg*" -or -name "psql" \) -exec basename {} ';' \
| xargs -pI{} ln -sf /opt/homebrew/Cellar/postgresql@15/15.8_1/bin/{} $HOME/bin/{}

# Start DBs
docker run --rm --name 'postgres' -d -p '5432:5432' -e POSTGRES_PASSWORD='password' 'postgres:14.12'
docker run --rm --name 'postgis'  -d -p '5432:5432' -e POSTGRES_PASSWORD='password' 'postgis/postgis:14-3.4'

# Start PgAdmin
# Retain data in a volume between sessions
docker run -d --name 'pgadmin' \
	--rm -v 'pgadmin-overrides:/pgadmin4' \
	--rm -v 'pgadmin-data:/var/lib/pgadmin' \
	-p 8080:80 \
	-e 'PGADMIN_DEFAULT_EMAIL=me@company.com' \
	-e 'PGADMIN_DEFAULT_PASSWORD=password' \
	'dpage/pgadmin4'


# Set up the credentials file
# Format => hostname:port:database:username:password
# Supports wildcards
cat <<EOF > ~/'.pgpass'
postgres.lan:5643:postgres:postgres:BananaORama
*:*:sales:elaine:modestPassword
EOF
chmod '600' ~/'.pgpass'

# Set up the per-user services file.
# do *not* use spaces around the '=' sign.
cat <<EOF > ~/'.pg_service.conf'
[prod]
host=prod.0123456789ab.eu-west-1.rds.amazonaws.com
port=5433
user=master
EOF

# Connect to DBs
psql 'postgres'
psql 'postgres' 'admin'
psql --host 'prod.db.lan' --port '5432' --username 'postgres' --database 'postgres' --password
psql -h 'host.fqnd' -p '5432' -U 'admin' -d 'postgres' -W
psql 'postgresql://localhost:5433/games?sslmode=require'
PGPASSWORD='password' psql 'host=host.fqdn port=5467 user=admin dbname=postgres'
psql "service=prod sslmode=require"

# List available databases
psql … --list

# Change passwords
psql … -U 'jonathan' -c '\password'
psql … -U 'admin' -c '\password jonathan'

# Execute SQL commands
psql … -c 'select * from tableName;' -o 'out.file'
psql … -c 'select * from tableName;' -H
psql … -f 'commands.sql'
psql … -f 'dump.sql' -e

# Dump DBs
pg_dump --host 'host.fqnd' --port '5432' --username 'postgres' --dbname 'postgres' --password
pg_dump -h 'host.fqnd' -p '5432' -U 'admin' -d 'postgres' -W
pg_dump -U 'postgres' -d 'sales' -F 'custom' -f 'sales.bak' --schema-only
pg_dump … -T 'customers,orders' -t 'salespeople,performances'
pg_dump … -s --format 'custom'
pg_dump … -F'd' --jobs '3'

# Dump DBs' schema only
pg_dump --host 'host.fqnd' --port '5432' --username 'postgres' --dbname 'postgres' --password --schema-only
pg_dump -h 'host.fqnd' -p '5432' -U 'admin' -d 'postgres' -Ws

# Dump users and groups to file
pg_dumpall -h 'host.fqnd' -p '5432' -U 'postgres' -l 'postgres' -W --roles-only --file 'roles.sql'
pg_dumpall -h 'host.fqnd' -p '5432' -U 'postgres' -l 'postgres' -Wrf 'roles.sql' --no-role-passwords

# Restore backups
pg_restore -U 'postgres' -d 'sales' 'sales.dump'
pg_restore -h 'host.fqdn' -U 'master' -d 'sales' -Oxj '8' 'sales.dump'

# Initialize a test DB
pgbench -i 'test-db'
pgbench -i 'test-db' -h 'hostname' -p '5555' -U 'user'

# Check a DB is ready for use
pg_isready -U 'denis' -d 'sales'

# Skip materialized views during a restore
pg_dump 'database' -Fc 'backup.dump'
pg_restore -l 'backup.dump' | sed '/MATERIALIZED VIEW DATA/d' > 'restore.lst'
pg_restore -L 'restore.lst' -d 'database' 'backup.dump'
# Only then, refresh with them
pg_restore -l 'backup.dump' | grep 'MATERIALIZED VIEW DATA' > 'refresh.lst'
pg_restore -L 'refresh.lst' -d 'database' 'backup.dump'
