# `dblab`

Database Lab Engine client CLI.

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
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Database Lab]
- [Database Lab Client CLI reference (dblab)]

### Sources

- [How to install and initialize Database Lab CLI]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[database lab]: database%20lab.md

<!-- Files -->
<!-- Upstream -->
[how to install and initialize database lab cli]: https://postgres.ai/docs/how-to-guides/cli/cli-install-init
[database lab client cli reference (dblab)]: https://postgres.ai/docs/reference-guides/dblab-client-cli-reference

<!-- Others -->
