# MySQL

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# connect with user "root" on the local default socket
# don't ask password and do not select db
mysql

# connect with user "user" on the local default socket
# ask for a password and execute a command
mysql -u user -p -e 'show databases;'

# provide a password on the cli
# put no spaces between -p and the password
mysql -u ${USERNAME} -h ${HOST} -p${PASSWORD} ${DATABASE}
```

```sql
-- list the available databases
SHOW DATABASES;
SHOW DATABASES LIKE 'open%';

-- list tables in the pizza_store database
use pizza_store;
show tables;

-- give permissions
grant ALL on db.* to 'username'@'localhost' identified by 'password';
grant ALL on db.* to 'username'@'127.0.0.1';
```

## Further readings

- [SQL]
- [PostgreSQL]

### Sources

- How to [list tables] in MySQL
- How to [show databases] in MySQL
- [phpimap issue 1549]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[postgresql]: postgresql/README.md
[sql]: sql.md

<!-- Others -->
[list tables]: https://alvinalexander.com/blog/post/mysql/list-tables-in-mysql-database/
[show databases]: https://linuxize.com/post/how-to-show-databases-in-mysql/
[phpimap issue 1549]: https://github.com/phpipam/phpipam/issues/1549
