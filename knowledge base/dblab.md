# `dblab`

DBLab Engine's CLI client.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Install.
curl -sSL 'dblab.sh' | bash

# Initialize CLI configuration.
# Assumes that 'localhost:2345' forwards to the Database Lab Engine machine's at port 2345'.
dblab init --environment-id 'tutorial' --url 'http://localhost:2345' --token 'secret_token' --insecure
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Fetch the status of the Engine's instance.
dblab instance status

# Create clones.
dblab clone create --username 'dblab_user_1' --password 'secret_password' --id 'my_first_clone'
curl -X 'POST' 'https://dblab.instance.fqdn/api/clone' -H 'Verification-Token: verification-token-here' \
  -H 'accept: application/json' -H 'content-type: application/json' \
  -d '{ "protected": true, "db": { "username": "user", "password": "password", "db_name": "db" }, "id": "clone-id" }'

# Get clones' information.
curl -X 'GET' 'https://dblab.instance.fqdn/api/clone/clone-id' -H 'Verification-Token: verification-token-here'

# Reset clones.
curl -X 'POST' 'https://dblab.instance.fqdn/api/clone/clone-id/reset' -H 'Verification-Token: verification-token-here' \
  -H 'accept: application/json' -H 'content-type: application/json' \
  -d '{ "latest": true }'
curl -X 'POST' 'https://dblab.instance.fqdn/api/clone/clone-id/reset' -H 'Verification-Token: verification-token-here' \
  -H 'accept: application/json' -H 'content-type: application/json' \
  -d '{ "latest": false, "snapshotID": "2024-09-09T12:12:13Z" }'

# Change clones' properties.
curl -X 'PATCH' 'https://dblab.instance.fqdn/api/clone/clone-id' -H 'Verification-Token: verification-token-here' \
  -H 'accept: application/json' -H 'content-type: application/json' \
  -d '{ "protected": false }'

# Delete clones.
curl -X 'DELETE' 'https://dblab.instance.fqdn/api/clone/clone-id/reset' -H 'Verification-Token: verification-token-here'
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
curl -X 'POST' 'https://dblab.company.com:1234/api/clone' \
  -H 'Verification-Token: something-something-dark-side' \
  -H 'accept: application/json' -H 'content-type: application/json' \
  -d '{
    "id": "smth",
    "protected": true,
    "db": {
      "username": "master",
      "password": "ofPuppets",
      "db_name": "puppet"
    }
  }'
curl 'https://dblab.company.com:1234/api/clone/smth' \
  -H 'Verification-Token: something-something-dark-side'
curl -X 'POST' 'https://dblab.company.com:1234/api/clone/smth/reset' \
  -H 'Verification-Token: something-something-dark-side' \
  -H 'accept: application/json' -H 'content-type: application/json' \
  -d '{ "latest": true }'
curl -X 'PATCH' 'https://dblab.company.com:1234/api/clone/smth' \
  -H 'Verification-Token: something-something-dark-side' \
  -H 'accept: application/json' -H 'content-type: application/json' \
  -d '{ "protected": false }'
curl -X 'DELETE' 'https://dblab.company.com:1234/api/clone/smth' \
  -H 'Verification-Token: something-something-dark-side'
```

</details>

## Further readings

- [DBLab engine]
- [Database Lab Client CLI reference (dblab)]
- [API reference]

### Sources

- [How to install and initialize Database Lab CLI]
- [How to refresh data when working in the "logical" mode]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[DBLab engine]: dblab%20engine.md

<!-- Files -->
<!-- Upstream -->
[API reference]: https://dblab.readme.io/reference/
[database lab client cli reference (dblab)]: https://postgres.ai/docs/reference-guides/dblab-client-cli-reference
[how to install and initialize database lab cli]: https://postgres.ai/docs/how-to-guides/cli/cli-install-init
[How to refresh data when working in the "logical" mode]: https://postgres.ai/docs/how-to-guides/administration/logical-full-refresh

<!-- Others -->
