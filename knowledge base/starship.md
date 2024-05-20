# Starship

Fast and customizable prompt for most shells.

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
1. [Further readings](#further-readings)

## TL;DR

<details>
  <summary>Installation and configuration</summary>

```sh
# Installation.
brew install 'starship'
zypper in 'starship'

# Start when the shell starts.
eval "$(starship init bash)" | tee -a ~'/.bashrc'
eval "$(starship init zsh)" | tee -a ~'/.zshrc'
echo 'starship init fish | source' | tee -a ~'/.config/fish/config.fish'

# Initialize starship configuration.
mkdir -p ~'/.config' && touch ~'/.config/starship.toml'

# Change configuration.
starship config
vim ~'/.config/starship.toml'

# Print the whole configuration.
starship print-config
cat ~'/.config/starship.toml'
```

</details>
<details>
  <summary>Usage</summary>

```sh
# List available presets (prompt styles).
starship preset -l
```

</details>

## Configuration

```sh
# Change configuration.
starship config
vim ~'/.config/starship.toml'

# Print the whole configuration.
starship print-config
cat ~'/.config/starship.toml'
```

```toml
# ~/.config/starship.toml

# Get editor completions based on the config schema.
"$schema" = 'https://starship.rs/config-schema.json'
command_timeout = 750

# Replace the default '❯' symbol in the prompt with '$'.
# The '$' character needs to be escaped.
[character]
success_symbol = '[\$](bold green)'
error_symbol = '[\$](bold red)'
```

## Further readings

- [Website]
- [Github]
- [Nerd fonts]
- [Bash]
- [Zsh]
- [Fish]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[bash]: bash.md
[fish]: fish.md
[nerd fonts]: nerd%20fonts.md
[zsh]: zsh.md

<!-- Files -->
<!-- Upstream -->
[github]: https://github.com/starship/starship
[website]: https://starship.rs/
