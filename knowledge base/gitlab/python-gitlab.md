# python-gitlab

Python wrapper for the GitLab API.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
docker pull $ docker run -it --rm registry.gitlab.com/python-gitlab/python-gitlab:latest <command> ...
pip install --upgrade 'python-gitlab'
pip install 'git+https://github.com/python-gitlab/python-gitlab.git'
pipx install 'python-gitlab'

export GITLAB_URL='https://gitlab.example.org' GITLAB_PRIVATE_TOKEN='glpat-ABC…id9'
```

The configuration file is at `~/.python-gitlab.cfg` by default.<br/>
Example::

```ini
[global]
default = exampleOrg
timeout = 10

[exampleOrg]
url = https://gitlab.example.org
private_token = glpat-ABC…id9
api_version = 4
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Run as container.
docker run -it --rm 'registry.gitlab.com/python-gitlab/python-gitlab' gitlab …

# Use specific configuration files.
gitlab --config-file 'path/to/config/file' …
gitlab -c 'path/to/config/file' …
PYTHON_GITLAB_CFG='path/to/config/file' gitlab …

# List users.
gitlab --order-by 'name' user list --get-all --per-page '100'

# Search for groups.
gitlab group list --search 'infra'
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

- [Website]
- [Codebase]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/python-gitlab/python-gitlab
[Documentation]: https://website/docs/
[Website]: https://website/

<!-- Others -->
