# SDKMAN

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Management</summary>

Configuration file: `${HOME}/.sdkman/etc/config`

```sh
# Install.
curl -s "https://get.sdkman.io" | bash
export SDKMAN_DIR="/path/to/custom/location" && curl -s "https://get.sdkman.io" | bash
curl -s "https://get.sdkman.io?rcupdate=false" | bash

# Initialize.
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Get help.
sdk help
sdk help 'install'

# Show the current SDKMAN version.
sdk version

# Change configuration values.
# Opens the editor defined by the 'EDITOR' variable.
sdk config

# Install a new version of SDKMAN! if available.
sdk selfupdate
sdk selfupdate force

# Uninstall.
# The initialization snippet must also be removed from the shells' RC dotfiles.
tar zcvf "${HOME}/sdkman-backup_$(date +%F-%kh%M).tar.gz" -C "$HOME" '.sdkman' \
&& rm -rf "${HOME}/.sdkman"
```

</details>

<details>
  <summary>Usage</summary>

```sh
# List available candidates.
sdk list
sdk list 'groovy'

# Install versions.
# When not given a version, 'latest' is implied.
sdk install 'java'
sdk install 'scala' '3.4.1'
sdk install 'java 17-zulu' '/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home'

# Show the currently used versions.
sdk current
sdk current 'java'

# Use specific versions in the current shell session.
sdk use 'scala' '3.4.1'

# Make versions the default.
sdk default 'scala' '3.4.1'

# Generate '.sdkmanrc' files.
# Those files work like `asdf`'s '.tool-versions' files.
sdk env init

# Install missing versions.
sdk env install

# Switch to the configuration defined by the '.sdkmanrc' file in the current directory.
sdk env

# Reset the versions to the default ones.
sdk env clear

# Get the absolute path of versions.
sdk home 'java' '21.0.2-tem'

# Flush the local state.
sdk flush

# Toggle online/offline mode.
sdk offline enable
sdk offline disable

# Refresh the available versions.
sdk update

# Upgrade versions.
sdk upgrade
sdk upgrade 'springboot'

# Remove installed versions.
sdk uninstall 'scala' '3.4.1'
```

</details>

<!-- Uncomment if needed
<details>
  <summary>Real world use cases</summary>
</details>
-->

## Further readings

- [Website]

### Sources

- [Usage]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[usage]: https://sdkman.io/usage
[website]: https://sdkman.io/

<!-- Others -->
