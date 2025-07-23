# Snowflake

Cloud-based [data warehousing][data warehouse] platform.

1. [TL;DR](#tldr)
1. [Roles](#roles)
1. [Users](#users)
1. [Virtual warehouses](#virtual-warehouses)
1. [Access with private keys](#access-with-private-keys)
1. [Snowflake CLI](#snowflake-cli)
1. [RoleOut](#roleout)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Snowflake separates storage, compute and cloud services in different layers.

It:

- Runs completely on cloud infrastructure.
- Handles semi-structured data like JSON and Parquet.
- Stores persistent data in columnar format in cloud storage.<br/>
  Customers cannot see nor access the data objects directly; they can only access them through SQL query operations.
- Copies data as Copy-on-Write virtual clones.
- Stores tables in memory in small chunks to enhance parallelization.

Each virtual warehouse is a dedicated MPP compute clusters. Each member handles a different part of a query.<br/>
Snowflake offers Virtual warehouses in different sizes at different prices (XS, S, M, L, XL, …, 6XL).

Billing depends on how long a warehouse runs continuously.<br/>
The total cost is the aggregate of the cost of using data transfer, storage, and compute resources.

Snowflake's system analyzes queries and identifies patterns to optimize using historical data. The results of frequently
executed queries is cached.

Administrators use Role-Based Access Control (RBAC) to define and manage user roles and permissions.

Accounts can connect to Snowflake via:

- Web UI.
- Command line clients.
- ODBC and JDBC drivers.
- Native connectors (e.g., Python or Spark).
- Third-party connectors.

<details>
  <summary>Setup</summary>

  <details style='padding: 0 0 0 1rem'>
    <summary>Mac OS X</summary>

```sh
# Install RoleOut's UI and CLI.
curl -C '-' -LfSO --url 'https://github.com/Snowflake-Labs/roleout/releases/download/v2.0.1/Roleout-2.0.1-arm64.dmg' \
&& sudo installer -pkg 'Roleout-2.0.1-arm64.dmg' -target '/' \
&& curl -C '-' -LfS --url 'https://github.com/Snowflake-Labs/roleout/releases/download/v2.0.1/roleout-cli-macos' \
     --output "$HOME/bin/roleout-cli" \
&& chmod 'u+x' "$HOME/bin/roleout-cli" \
&& xattr -d 'com.apple.quarantine' "$HOME/bin/roleout-cli"
```

  </details>

</details>

<details>
  <summary>Usage</summary>

```sql
-- List users
SHOW USERS;
SHOW USERS LIKE '%john%';

-- Get information about users
DESC USER zoe;

-- Create users
CREATE USER alice;
CREATE USER IF NOT EXISTS bob;
CREATE OR REPLACE USER claude
  PASSWORD='somePassword' DISPLAY_NAME='Claude' EMAIL='claude@example.org'
  LOGIN_NAME='CLAUDE@EXAMPLE.ORG' MUST_CHANGE_PASSWORD=TRUE;

-- Make changes to users
ALTER USER IF EXISTS elijah RESET PASSWORD;
ALTER USER fred SET DISABLE_MFA=TRUE;
ALTER USER greg SET MINS_TO_UNLOCK=0;

-- Delete users
DROP USER snowman;


-- List roles
SHOW ROLES;
SHOW ROLES LIKE '%DATA%';

-- Grant permissions
GRANT ROLE someRole TO USER diane;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE SYSADMIN;

-- Show permissions resources have
SHOW GRANTS TO USER CLAUDE;
-- Show permissions the current user has on resources
SHOW GRANTS ON USER CLAUDE;


-- FIXME
DROP DATABASE IF EXISTS sf_tuts;
DROP WAREHOUSE IF EXISTS sf_tuts_wh;
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Roles

Entities to which privileges on securable objects can be granted and revoked.<br/>
They are assigned to [users] to allow them to perform actions required for business functions in their organization

Snowflake accounts come with a set of system-defined roles:

- `GLOBALORGADMIN`: the organization administrator.<br/>
  Manages the lifecycle of accounts and views organization-level usage information.<br/>
  This role exists only in the organization account. Replaces `ORGADMIN`.
- `ACCOUNTADMIN`: the account administrator.<br/>
  Encapsulates the `SYSADMIN` and `SECURITYADMIN` roles.<br/>
  Top-level role in the system with access to every component. It should be granted only to a limited and controlled
  number of users in the account.
- `SECURITYADMIN`: the security administrator.<br/>
  Manages any object grant globally. Creates, monitors, and manages users and roles.

  <details style='padding: 0 0 1rem 1rem'>

  This role is granted `MANAGE GRANTS` privilege to be able to modify any grant, including revoking it.<br/>
  It does **not**, though, give the `SECURITYADMIN` the ability to perform **other** actions like creating objects. To
  do so, the role must **also** be granted the privileges needed for those actions.

  It is also granted the `USERADMIN` role.

  </details>

- `USERADMIN`: the user and role administrator.<br/>
  Can create users and roles in the account. It also manages users and roles that it owns.

  <details style='padding: 0 0 1rem 1rem'>

  This role is granted the `CREATE USER` and `CREATE ROLE` privileges.

  Only roles with the `OWNERSHIP` privilege on an object (user or role in this case), or a higher role, can modify an
  object's properties.

  </details>

- `SYSADMIN`: the system Administrator.<br/>
  It has privileges to create warehouses, databases, and other objects in an account.
- `PUBLIC`: pseudo-role automatically granted by default to every user and every role in an account.<br/>
  Can own securable objects, but they are, by definition, available to every other user and role in the account.<br/>
  Typically used in cases where explicit access control is not needed.

```sql
-- List roles
SHOW ROLES;
SHOW ROLES LIKE '%DATA%';

-- Assume roles
USE ROLE SECURITYADMIN;

-- Grant permissions
GRANT ROLE FINANCIAL_CHIEF TO USER CLAUDE;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE SYSADMIN;

-- Show permissions users have
SHOW GRANTS TO USER CLAUDE;
-- Show permissions the current user has on other users
SHOW GRANTS ON USER CLAUDE;
```

## Users

Users can only be created by those with (or):

- The `USERADMIN` role or higher.
- Roles granting them the CREATE USER capability on the account.

Add users to the account executing a SQL Query by means of Snowflake's web UI found in the `Account` section.

```sql
-- List users
SHOW USERS;
SHOW USERS LIKE '%john%';

-- Get information about users
DESC USER zoe;

-- Create users
CREATE USER alice;
CREATE USER IF NOT EXISTS bob;
CREATE OR REPLACE USER claude
  LOGIN_NAME='CLAUDE@EXAMPLE.ORG' DISPLAY_NAME='Claude' EMAIL='claude@example.org'
  PASSWORD='somePassword' MUST_CHANGE_PASSWORD=TRUE;
```

Prefer setting a `DEFAULT_WAREHOUSE` and `DEFAULT_ROLE` for users, specially if they use non-Snowflake client tools.

Remember to `GRANT ROLE a=Access` after creating a user.<br/>
Snowflake does **not** offer access to a user's default role automatically. After a user is created, one **must**
provide that user access to its default role.<br/>
If a user can't access their default role, they won't be able to log in.

When using SSO:

- The users' LOGIN NAME must exactly match the email address used by one's Identity Provider.<br/>
  Mismatches or fresh email addresses will result in a failed SSO attempt.
- Optionally remove the ability for a user to log in with a password by not specifying one in the creation command.<br/>
  To give someone the ability to use a password later, simply modify that user's password and require them to change
  it.<br/>
  Setting up a password gives the user the option of selecting what method to use to login. This is required by tools
  that do not support logging in via SSO.

## Virtual warehouses

Dedicated, independent clusters of compute resources in Snowflake.

They are required for queries and all DML operations, including loading data into tables.

Available in two types: _Standard_ or _Snowpark-optimized_.<br/>
Type aside, warehouses are defined by their size and those other properties that control and automate their activity.

Billing depends on how long the warehouse runs continuously.

Warehouses can be set to automatically resume or suspend, based on activity.<br/>
Auto-suspend and resume are both enabled by default.

## Access with private keys

Refer [Snowflake terraform provider authentication].

Procedure:

1. Generate a keypair.

   ```sh
   openssl genrsa -out "$HOME/.ssh/snowflake_key" 4096
   openssl rsa -in "$HOME/.ssh/snowflake_key" -pubout -out "$HOME/.ssh/snowflake_key.pub"
   openssl pkcs8 -topk8 -inform 'pem' -in "$HOME/.ssh/snowflake_key" \
     -outform 'PEM' -v2 aes-256-cbc -out "$HOME/.ssh/snowflake_key.p8"
   ```

1. Assign the key to your user in Snowflake.

   ```sql
   ALTER USER jsmith SET RSA_PUBLIC_KEY='MIIBIjANBgkqh...';
   ```

1. Configure tools to use the key.

   ```sh
   export SNOWFLAKE_PRIVATE_KEY="$(cat ~/.ssh/snowflake_key.p8)"
   export SNOWFLAKE_PRIVATE_KEY_PATH="$HOME/.ssh/snowflake_key" SNOWFLAKE_PRIVATE_KEY_PASSPHRASE='somePassword'
   snow connection add -n 'jwt' --authenticator 'SNOWFLAKE_JWT' --private-key-file "$HOME/.ssh/snowflake_key"
   ```

## Snowflake CLI

See [Snowflake CLI].

## RoleOut

Refer [RoleOut].

## Further readings

- [Website]
- [Documentation]
- [Data warehouse]
- [Snowflake CLI]
- [Roleout]

### Sources

- [Snowflake CREATE USERS: Syntax, Usage & Practical Examples]
- [Overview of Access Control]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[users]: #users

<!-- Knowledge base -->
[Data warehouse]: ../data%20warehouse.md
[RoleOut]: roleout.md
[Snowflake CLI]: cli.md

<!-- Files -->
<!-- Upstream -->
[Documentation]: https://docs.snowflake.com/en/
[Overview of Access Control]: https://docs.snowflake.com/en/user-guide/security-access-control-overview
[Website]: https://www.snowflake.com/en/

<!-- Others -->
[Snowflake CREATE USERS: Syntax, Usage & Practical Examples]: https://hevodata.com/learn/snowflake-create-users/
[Snowflake terraform provider authentication]: https://registry.terraform.io/providers/Snowflake-Labs/snowflake/latest/docs#authentication
