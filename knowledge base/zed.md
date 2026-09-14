# ZED

Next-generation code editor.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

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

Disable telemetry:

```json
"telemetry": {
    "diagnostics": false,
    "metrics": false
}
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
