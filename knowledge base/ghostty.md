# Ghostty

Fast, feature-rich, and cross-platform terminal emulator that uses platform-native UI and GPU acceleration.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Designed to work out of the box with no configuration for most users.\
Ships with _sensible_ defaults and built-in fonts.

Configured using a text-based configuration file loaded on the following priority (first found wins):

1. `$XDG_CONFIG_HOME/ghostty/config.ghostty`
1. `$XDG_CONFIG_HOME/ghostty/config`
1. `$HOME/.config/ghostty/config`

Configuration values consist of key-value pairs, separated by the `=` signs. Spaces around that separator are ignored.\
Empty values reset their configuration key to its default.\
Comment lines start with `#`, and **cannot** be placed on the same line of a value. Doing so would trick Ghostty into
considering the comment as part of the value.\
Some options require unique syntaxes for their value (e.g., `resize-overlay-duration = 4s 200ms`). Check the
[documentation] for them.

Reload the configuration file while running by using the menu option or the bound key (which defaults to `Cmd+Shift+,`
on macOS and `Ctrl+Shift+,` on other platforms).\
Some options do not allow being reloaded while running. Some of those only apply to new windows. Others may require
Ghostty to fully restart to take effect.

<details>
  <summary>Setup</summary>

```sh
# Install.
brew install --cask 'ghostty'

# View a list of all available configuration options with their default values.
ghostty +show-config --default --docs
```

</details>

<details>
  <summary>Usage</summary>

```sh
# List available values.
ghostty +list-fonts
ghostty +list-themes
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
[Codebase]: https://github.com/ghostty-org/ghostty
[Documentation]: https://ghostty.org/docs
[Website]: https://ghostty.org/

<!-- Others -->
