# Starship

Fast and customizable prompt for most shells.

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
1. [Further readings](#further-readings)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Installation.
apt install 'starship'
brew install 'starship'
zypper in 'starship'

# Initialize starship configuration.
mkdir -p ~'/.config' && touch ~'/.config/starship.toml'

# Start when the shell starts.
eval "$(starship init bash)" | tee -a ~'/.bashrc'
eval "$(starship init zsh)" | tee -a ~'/.zshrc'
mkdir -p ~'/.config/fish' && cat <<EOF | tee -a ~'/.config/fish/conf.d/zzz_starship.fish'
if status is-interactive
  starship init fish | source
end
EOF

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
- [Codebase]
- Shells: [Bash], [Fish], [Zsh]
- [Nerd fonts]

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
[Codebase]: https://github.com/starship/starship
[Website]: https://starship.rs/
