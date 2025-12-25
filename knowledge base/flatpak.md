# Flatpak

## TL;DR

<details>
  <summary>Setup</summary>

```sh
apt install 'flatpak'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# List installed applications and runtimes.
flatpak list
flatpak list --app

# List remotes.
flatpak remotes
flatpak remotes --user

# Add remotes.
flatpak remote-add --if-not-exists 'flathub' 'https://flathub.org/repo/flathub.flatpakrepo'
flatpak remote-add --user --if-not-exists 'flathub' 'https://flathub.org/repo/flathub.flatpakrepo'

# Search for applications.
flatpak search 'vscode'

# Install applications.
flatpak install 'someRemote' 'org.stellarium.Stellarium'
flatpak install --user 'flathub' 'com.visualstudio.code-oss'
flatpak install 'https://flathub.org/repo/appstream/org.gimp.GIMP.flatpakref'

# Run applications.
flatpak run 'org.gimp.GIMP'

# Update applications.
flatpak update

# Uninstall applications.
flatpak uninstall 'org.stellarium.Stellarium'
flatpak uninstall --unused
flatpak uninstall --delete-data 'edu.berkeley.BOINC'

# Remove remotes.
flatpak remote-delete 'flathub'

# Fix inconsistencies.
flatpak repair

# Reset applications' permissions.
flatpak permission-reset 'org.gimp.GIMP'

# List operations.
flatpak history
```

</details>

## Further readings

- [Using Flatpak] getting started guide on the official [documentation].

### Sources

- [How to clean up Flatpak apps to clear disk space]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[documentation]: https://docs.flatpak.org/en/latest/
[using flatpak]: https://docs.flatpak.org/en/latest/using-flatpak.html

<!-- Others -->
[how to clean up flatpak apps to clear disk space]: https://www.debugpoint.com/2021/10/clean-up-flatpak/
