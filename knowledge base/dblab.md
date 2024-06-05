# `dblab`

Database Lab Engine client CLI.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Installation and configuration</summary>

```sh
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
- [Website]
- [Main repository]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[database lab]: database%20lab.md

<!-- Files -->
<!-- Upstream -->
[main repository]: https://github.com/project/
[website]: https://website/

<!-- Others -->
