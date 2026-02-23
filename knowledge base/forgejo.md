# Forgejo

Community-driven code forge platform similar to GitHub.<br/>
Forked from [Gitea] after the for-profit company Gitea Ltd took control of it.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
docker pull 'codeberg.org/forgejo/forgejo'  # or 'data.forgejo.org/forgejo/forgejo'
```

The configuration uses the INI format.<br/>
When installing from a distribution, the configuration file will _typically_ be placed at `/etc/forgejo/app.ini`.<br/>
When using the container image, the configuration file is automatically created if it does not already exist.<br/>
Refer the [configuration cheat sheet] and the [configuration file defaults].

Values containing `#` or `;` must be quoted using `` ` `` or `"""`.

> [!important]
> Forgejo requires a **full** restart for configuration changes to take effect.

Configuration values can be _**added**_ or _**overridden**_ by setting environment variables that follow the
`FORGEJO__[SECTION]__[KEY]` format.<br/>
The `DEFAULT` section of the configuration should be an empty string.

  <details style='padding: 0 0 1rem 1rem'>

Setting environment variables as follows:

```sh
FORGEJO____APP_NAME=Frogejo 🐸
FORGEJO__repository__ENABLE_PUSH_CREATE_USER=true
```

is equivalent to adding the following to the `app.ini` configuration file:

```ini
APP_NAME=Frogejo 🐸

[repository]
ENABLE_PUSH_CREATE_USER = true
```

  </details>

Existing configuration values must be _**removed**_ by editing the configuration file.

> [!important]
> Using SELinux environments could trigger issues with containers.<br/>
> Check the audit logs in this case.

</details>

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Website]
- [Codebase]
- [News]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Gitea]: gitea.md

<!-- Files -->
<!-- Upstream -->
[Codebase]: https://codeberg.org/forgejo/forgejo
[Configuration cheat sheet]: https://forgejo.org/docs/latest/admin/config-cheat-sheet/
[Configuration file defaults]: https://codeberg.org/forgejo/forgejo/src/branch/forgejo/custom/conf/app.example.ini
[Documentation]: https://forgejo.org/docs/latest/
[News]: https://forgejo.org/news/
[Website]: https://forgejo.org/

<!-- Others -->
