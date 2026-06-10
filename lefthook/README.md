# Lefthook extended configurations

## Tool path templates

Each configuration file references the tools it uses via a `{<tool>_bin}` template.<br/>
Its value is the project-local installation path:

```yaml
templates:
  venv_dir: .venv
  yq_bin: .venv/bin/yq

bootstrap:
  commands:
    yq:
      run: >-
        python3 -m 'venv' '{venv_dir}'
        && {venv_dir}/bin/pip install --require-virtualenv 'yq'

pre-commit:
  commands:
    validate-yaml:
      run: "{yq_bin} '.' {staged_files} > /dev/null && echo 'All YAML files are readable'"
```

The files use:

- [uv]'s default path (`.venv/bin/`) for Python tools.
- [npm]'s default path (`node_modules/.bin/`) for Node tools.

The `bootstrap:` group of each file creates the virtual environments using the same templates.<br/>
Doing this allows overriding those paths **locally** in a `lefthook-local.yml` file.

<details style='padding: 0 0 1rem 1rem'>

```yaml
templates:
  yq_bin: /path/to/custom/yq
```

</details>

> [!important]
> Templates in a single-line `run:` must be **quoted**, or the key should use a folded scalar (`run: >-`).<br/>
> Values starting with `{` would start a YAML flow mapping.

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[npm]: ../knowledge%20base/node.js.md
[uv]: ../knowledge%20base/uv.md
