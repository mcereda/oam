# ZED

Next-generation code editor.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
brew install --cask 'zed'
sudo zypper ar 'https://download.opensuse.org/repositories/editors/openSUSE_Tumbleweed/editors.repo' \
  && sudo zypper in 'zed'
```

Global settings at `~/.config/zed/settings.json`.\
Folder-specific settings at `.zed/settings.json`.\
Reference at [All Settings].

The settings file's schema is included in Zed and the file is identified automatically.\
One _can_ make it explicit by using its internal URL:

```json
"$schema": "zed://schemas/settings"
```

Disable telemetry:

```json
"telemetry": {
    "diagnostics": false,
    "metrics": false
}
```

Disable all AI features:

```json
"disable_ai": true
```

Change the terminal's default shell:

```json
"terminal": {
    "shell": {
        "program": "fish"
    },
}
```

Show wrapping guides:

```json
"wrap_guides": [
    80,
    120
]
```

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
[All Settings]: https://zed.dev/docs/reference/all-settings
[Codebase]: https://github.com/zed-industries/zed
[Documentation]: https://zed.dev/docs/
[Website]: https://zed.dev/

<!-- Others -->
