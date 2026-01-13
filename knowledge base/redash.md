# Redash

> TODO

Intro

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Authentication](#authentication)
   1. [Password](#password)
   1. [Google OAuth](#google-oauth)
   1. [LDAP or Active Directory](#ldap-or-active-directory)
1. [API](#api)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Settings are read by `redash.settings` from environment variables.<br/>
Most installations set them in `/opt/redash/.env`. Official container images require that `.env` file in the root
directory.<br/>
Reference available variables from [Environment Variables Settings].

<!-- Uncomment if used
<details>
  <summary>Setup</summary>

```sh
```

</details>
-->

<details>
  <summary>Usage</summary>

```sh
# Migrate the DB.
docker compose run --rm 'server' manage db upgrade
docker run --rm --name 'redash-db-migrations' \
  --env 'REDASH_COOKIE_SECRET' --env 'REDASH_DATABASE_URL' --env 'REDASH_REDIS_URL' \
  'redash/redash' -- manage db upgrade
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Migrate the DB from the ECS service when running in AWS.
# Requires command execution to be enabled and working.
aws ecs list-tasks --cluster 'someCluster' --service-name 'redash' --query 'taskArns[0]' --output 'text' \
| xargs -oI '%%' aws ecs execute-command --cluster 'someCluster' --container 'redash' --task '%%' --interactive \
    --command 'manage db upgrade'

# Migrate the DB from localhost when running in AWS.
REDASH_IMAGE="$(\
  aws ecs list-tasks --cluster 'someCluster' --service-name 'redash' --query 'taskArns[0]' --output 'text' \
  | xargs -oI '%%' aws ecs describe-tasks --cluster 'someCluster' --task '%%' --output 'text' \
        --query 'tasks[].containers[?name==`server`].image' \
)"
REDASH_DATABASE_URL="$(\
  aws rds describe-db-instances --db-instance-identifier 'redash' --output 'text' \
    --query '
      DBInstances[0]
      | join(``, [
          `postgresql://`,MasterUsername,`:`,`PASSWORD`,`@`,Endpoint.Address,`:`,to_string(Endpoint.Port),`/`,
          DBName || `postgres`
        ])
    ' \
)"
REDASH_REDIS_URL="$(\
  aws elasticache describe-replication-groups --replication-group-id 'redash' --output 'text' \
    --query '
      ReplicationGroups[].NodeGroups[].PrimaryEndpoint[]
      .join(``,[`redis://`,Address,`:`,to_string(Port),`/0`])
    ' \
)"
REDASH_COOKIE_SECRET="aa…Wd"
docker run --rm --name 'redash-db-migrations' --platform 'linux/amd64' --dns '172.31.0.2' \
  --env 'REDASH_COOKIE_SECRET' --env 'REDASH_DATABASE_URL' --env 'REDASH_REDIS_URL' \
  "$REDASH_IMAGE" manage db upgrade
```

</details>

Refer [How to Upgrade] when upgrading a self-hosted instance.

When updating Redash or its dependencies (i.e., DB and redis cache):

1. Stop Redash's components.

   <details>

   ```sh
   docker compose stop 'server' 'scheduler' 'scheduled_worker' 'adhoc_worker'
   ```

   </details>

   The scheduler will exit should it suddenly be unable to write to the cache.<br/>
   This usually happens when upgrading the cache's cluster when Redash is still active.

1. Make a backup of the data (DB).
1. \[if needed] Update Redash's dependencies.
1. Make sure the DB has enough storage space for the migrations to run.
1. Update Redash.
1. \[if needed] Run the migration scripts.

   <details>

   ```sh
   docker compose run --rm 'server' manage db upgrade
   ```

   </details>

1. Restart Redash's components.

   <details>

   ```sh
   docker compose up -d
   ```

   </details>

## Authentication

Refer [Authentication Settings].

Authentication options are configured through **a mix** of Environment variables and UI (under _Settings_ > _General_).

> [!important]
> Only admins can view and change authentication settings.<br/>
> Some authentication options will **not** appear in the UI until the corresponding environment variables have been set.

Redash uses the [Password] method by default.

### Password

Redash authenticates users with their email address and password.

This is configured in the settings' `Password Login` section.<br/>
After one enables an alternative authentication method, they can disable login via password.

Redash stores the hashes of those user passwords that were created through its default password configuration.

Authenticating through SAML or Google Login for the first time creates a user record, but does **not** store a password
hash.<br/>
This is called Just-in-Time (JIT) provisioning.<br/>
These users can **only** log-in through third-party authentication services.

When using Password Login and subsequently enable Google OAuth or SAML 2.0, it is possible for that user to log-in to
Redash using a single email address but two passwords (their Google/SAML password, and their local Redash password).

> [!tip]
> Prefer disabling Password Login if users are expected to authenticate through third-party authentication services.

### Google OAuth

Allow any user with a Google account from the designated domains to login to Redash.<br/>
If the user doesn't have an account yet, Redash will create one automatically.

To enable this method:

1. Register the Redash instance with your Google organization by:
   1. Creating a developers project if one does not exist already, and following the _Create Credentials_ flow in that
      case.<br/>
      The setup will give back a client id and a client secret. Note them down, as those will be used later.
   1. Setting the _Authorized Redirect URLs_ to `http(s)://${REDASH_BASEURL}/oauth/google_callback`.
   1. Set the instance's `REDASH_GOOGLE_CLIENT_ID` and `REDASH_GOOGLE_CLIENT_SECRET` environment variables to the
      credentials given back by the setup step above.
   1. Restart the Redash instance.

Only visitors with an existing Redash account can sign-in using the Google Login flow.<br/>
As for the [Password] method, visitors without an account cannot login unless they receive an invitation from an admin.

Optionally configure Redash to allow any user from a specified domain to login by completing the
_Allowed Google Apps Domains_ box in _Settings_ > _General_.<br/>
Redash will create an account automatically for them on first login, if one does not already exist.

### LDAP or Active Directory

Refer [LDAP/AD Authentication].

## API

Refer [API].

Prefer acting on them via [getredash/redash-toolbelt].

<details style='padding: 0 0 1rem 1rem'>
  <summary>Data sources</summary>

```plaintext
GET /api/data_sources
GET /api/data_sources/42

POST /api/data_sources
{
  "name": "some data source",
  "type": "pg",
  "options": {
    "host": "db.fqdn",
    "port": 5432,
    "dbname": "postgres",
    "user": "postgres",
    "password": "someStr0ngPa$$w0rd",
  }
}
```

```sh
curl --request 'GET' --url 'https://redash.example.org/api/data_sources' --header 'Authorization: Key AA…99'

curl --request 'POST' --url 'https://redash.example.org/api/data_sources' \
  --header 'Authorization: Key AA…99' \
  --header 'Content-Type: application/json' \
  --data '{
    "name": "some data source",
    "type": "pg",
    "options": {
      "host": "db.fqdn",
      "port": 5432,
      "dbname": "postgres",
      "user": "postgres",
      "password": "someStr0ngPa$$w0rd",
    }
  }'
```

```py
from redash_toolbelt import Redash
from requests import Response

data_source_name: str = 'some data source'
data_source_type: str = 'pg'
data_source_options: object = {
    host = 'db.fqdn',
    port = 5432,  # must be int
    dbname = 'postgres',
    user = 'postgres',
    password = 'someStr0ngPa$$w0rd',
}

response: Response = redash.create_data_source(data_source_name, data_source_type, data_source_options)
```

</details>

<details style='padding: 0 0 1rem 1rem'>
  <summary>Settings</summary>

```plaintext
POST /api/settings/organization
{
  "auth_password_login_enabled": true,
  "hide_plotly_mode_bar": true,
  …
}
```

```sh
curl --request 'POST' --url 'https://redash.example.org/api/settings/organization' \
  --header 'Authorization: Key AA…99' \
  --header 'Content-Type: application/json' \
  --data '{"auth_password_login_enabled": true}'
```

</details>

## Further readings

- [Website]
- [Codebase]

### Sources

- [Documentation]
- [Ask Devin]
- [Setting up a Redash Instance]
- [API]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Password]: #password

<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[API]: https://redash.io/help/user-guide/integrations-and-api/api/
[Authentication Settings]: https://redash.io/help/user-guide/users/authentication-options/
[Codebase]: https://github.com/getredash/redash
[Documentation]: https://redash.io/help/
[Environment Variables Settings]: https://redash.io/help/open-source/admin-guide/env-vars-settings/
[getredash/redash-toolbelt]: https://github.com/getredash/redash-toolbelt
[How to Upgrade]: https://redash.io/help/open-source/admin-guide/how-to-upgrade/
[LDAP/AD Authentication]: https://redash.io/help/open-source/admin-guide/ldap-authentication/
[Setting up a Redash Instance]: https://redash.io/help/open-source/setup/
[Website]: https://redash.io/

<!-- Others -->
[Ask Devin]: https://deepwiki.com/getredash/redash
