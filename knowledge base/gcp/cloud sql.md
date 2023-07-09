# Cloud SQL

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Connect to a cloud SQL instance](#connect-to-a-cloud-sql-instance)
1. [Create users in a SQL instance from the MySQL shell](#create-users-in-a-sql-instance-from-the-mysql-shell)
1. [Use Terraform to manage users in a cloud SQL instance](#use-terraform-to-manage-users-in-a-cloud-sql-instance)
1. [Gotchas](#gotchas)

## TL;DR

```sh
# Connect to cloud SQL instances.
gcloud sql connect 'instance-name' --user='root' --quiet

# Connect to cloud SQL instances trough local proxy.
# brew install 'cloud_sql_proxy'
cloud_sql_proxy -instances=project-name:region:instance-name=tcp:3306
cloud_sql_proxy -instances=project-name:region:instance-name -dir=/tmp \
  -verbose -log_debug_stdout
```

## Connect to a cloud SQL instance

```sh
$ gcloud sql connect 'instance-name' --user=root --quiet
Allowlisting your IP for incoming connection for 5 minutes...done.
Connecting to database with SQL user [root].Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 293
Server version: 8.0.18-google (Google)

Copyright (c) 2000, 2021, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql>
```

## Create users in a SQL instance from the MySQL shell

1. Create an administrative user for the instance using `gcloud`, the APIs or the console;
1. Use this administrative user to connect to the MySQL console:

   ```sh
   mysql -h 'host' -u 'admin' -p
   ```

1. Create the new users from there.

## Use Terraform to manage users in a cloud SQL instance

- Make sure the SQL instance has been created (using a IaC tool or not, it doesn't matter);
- Install `cloud_sql_proxy` on your machine:

  ```sh
  brew install 'cloud_sql_proxy'
  ```

- Start the proxy and point it to the SQL instance the code needs to connect to:

  ```sh
  $ cloud_sql_proxy -instances=myAwesomeProject:europe-west4:sqlInstance=tcp:3306 -verbose -log_debug_stdout
  2021/04/20 10:49:03 Rlimits for file descriptors set to {Current = 8500, Max = 9223372036854775807}
  2021/04/20 10:49:05 Listening on 127.0.0.1:3306 for myAwesomeProject:europe-west4:sqlInstance
  2021/04/20 10:49:05 Ready for new connections

  # or, using sockets
  $ cloud_sql_proxy -instances=myAwesomeProject:europe-west4:sqlInstance -dir=/tmp -verbose -log_debug_stdout
  2021/05/19 23:13:40 Rlimits for file descriptors set to {Current = 8500, Max = 9223372036854775807}
  2021/05/19 23:13:41 Listening on /tmp/myAwesomeProject:europe-west4:sqlInstance for myAwesomeProject:europe-west4:sqlInstance
  2021/05/19 23:13:41 Ready for new connections
  ```

- Point the Terraform SQL provider to localhost:

  ```hcl
  provider "mysql" {
    # endpoint = google_sql_database_instance.sqlInstance.first_ip_address
    # endpoint = "127.0.0.1"
    endpoint = "/tmp/myAwesomeProject:europe-west4:sqlInstance"
    username = "admin"
    password = var.sql_password
    version  = "~> 1.9"
  }
  ```

- Execute `terraform plan` or whatever other action from your machine.

Terraform will use the provider to connect to the proxy and operate on the SQL instance.

## Gotchas

- As of 2021-05-18 the `root` user will **not be able** to create other users from the MySQL shell because it will lack `CREATE USER` permissions.  
- The documentation says that SQL users created using `gcloud`, the APIs or the cloud console will have the same permissions of the `root` user; in reality, those administrative entities will be able to create users only from the MySQL shell.
