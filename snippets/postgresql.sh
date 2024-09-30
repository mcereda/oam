#!/usr/bin/env sh

# Connect to DBs
psql 'postgres'
psql 'postgres' 'admin'
psql --host 'prod.db.lan' --port '5432' --username 'postgres' --database 'postgres' --password
psql -h 'host.fqnd' -p '5432' -U 'admin' -d 'postgres' -W
psql 'postgresql://localhost:5433/games?sslmode=require'
psql 'host=host.fqdn port=5467 user=admin dbname=postgres'

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

# Dump DBs' schema only
pg_dump --host 'host.fqnd' --port '5432' --username 'postgres' --dbname 'postgres' --password --schema-only
pg_dump -h 'host.fqnd' -p '5432' -U 'admin' -d 'postgres' -Ws

# Dump users and groups to file
pg_dumpall -h 'host.fqnd' -p '5432' -U 'postgres' -l 'postgres' -W --roles-only --file 'roles.sql'
pg_dumpall -h 'host.fqnd' -p '5432' -U 'postgres' -l 'postgres' -Wrf 'roles.sql' --no-role-passwords

# Restore backups
pg_restore -U 'postgres' -d 'sales' 'sales.dump'
pg_restore -h 'host.fqdn' -U 'master' -d 'sales' -Oxj 8 'sales.dump'

# Initialize a test DB
pgbench -i 'test-db'
pgbench -i 'test-db' -h 'hostname' -p '5555' -U 'user'
