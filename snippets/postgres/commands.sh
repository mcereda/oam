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
psql 'host=host.fqdn port=5467 user=admin dbname=postgres'
psql "service=prod sslmode=require"
PGHOST='host.fqdn' PGPORT=5432 PGDATABASE='postgres' PGUSER='postgres' PGPASSWORD='somePassword' …

# List available databases
psql --list

# Change passwords
psql … -U 'jonathan' -c '\password'
psql … -U 'admin' -c '\password jonathan'

# Execute SQL commands
# The action is done in a single transaction
psql -c 'select * from tableName;' -o 'out.file'
psql -c 'select * from tableName;' -H
psql -f 'commands.sql'
psql -f 'dump.sql' -e

# Dump DBs
pg_dump --host 'host.fqnd' --port '5432' --username 'postgres' --dbname 'postgres' --password
pg_dump -h 'host.fqnd' -p '5432' -U 'admin' -d 'postgres' -W
pg_dump -U 'postgres' -d 'sales' -F 'custom' -f 'sales.bak' --schema-only
pg_dump … -T 'customers,orders' -t 'salespeople,performances'
pg_dump … -s --format 'custom'
pg_dump … -F'd' --jobs '3'

# Dump DBs' schema only
pg_dump … --schema-only

# Dump only users and groups to file
pg_dumpall … --roles-only --file 'roles.sql'
pg_dumpall … -rf 'roles.sql' --no-role-passwords

# Restore backups
pg_restore … --dbname 'sales' 'sales.dump'
pg_restore … -d 'sales' -Oxj '8' 'sales.dump'
pg_restore … -d 'sales' --clean --if-exists 'sales.dump'

# Initialize a test DB
pgbench … -i 'test-db'

# Check a DB is ready for use
pg_isready

# Skip materialized views during a restore
pg_dump 'database' -Fc 'backup.dump'
pg_restore --list 'backup.dump' | sed -E '/[[:digit:]]+ VIEW/,+1d' > 'no-views.lst'
pg_restore -d 'database' --use-list 'no-views.lst' 'backup.dump'
# Only then, if needed, refresh the dump with the views
pg_restore --list 'backup.dump' | grep -E --after-context=1 '[[:digit:]]+ VIEW' | sed '/--/d' > 'only-views.lst'
pg_restore -d 'database' --use-list 'only-views.lst' 'backup.dump'

# Recreate databases
# Cannot be done in a single transaction
psql -c 'DROP DATABASE IF EXISTS sales;' && psql -c 'CREATE DATABASE sales;'
dropdb --if-exists 'sales' && createdb 'sales'
