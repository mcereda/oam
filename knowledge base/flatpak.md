# Flatpak

## TL;DR

```shell
# List installed applications and runtimes.
flatpak list
flatpak list --app

# List remotes.
flatpak remotes

# Add remotes.
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Search for applications.
flatpak search vscode

# Install applications.
flatpak install fedora org.stellarium.Stellarium
flatpak install --user flathub com.visualstudio.code-oss
flatpak install https://flathub.org/repo/appstream/org.gimp.GIMP.flatpakref

# Run applications.
flatpak run org.gimp.GIMP

# Update applications.
flatpak update

# Uninstall applications.
flatpak uninstall org.stellarium.Stellarium
flatpak uninstall --unused

# Remove remotes.
flatpak remote-delete flathub

# Fix inconsitencies.
flatpak repair

# Reset applications' permissions.
flatpak permission-reset org.gimp.GIMP

# List operations.
flatpak history
```

## Further readings

- [Using Flatpak] getting started guide on the official [documentation]

[documentation]: https://docs.flatpak.org/en/latest/
[using flatpak]: https://docs.flatpak.org/en/latest/using-flatpak.html

## Sources

- [How to clean up Flatpak apps to clear disk space]

[how to clean up flatpak apps to clear disk space]: https://www.debugpoint.com/2021/10/clean-up-flatpak/
