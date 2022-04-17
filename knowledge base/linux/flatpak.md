# Flatpak

## TL;DR

```shell
# add the `flathub` remote
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# search for `vscode`
flatpak search vscode

# install `vscode`
flatpak install --user flathub com.visualstudio.code-oss

# uninstall unused packages
flatpak uninstall --unused
```

## Further readings

- [Using Flatpak] getting started guide on the official [documentation]
- [How to clean up Flatpak apps to clear disk space]

[documentation]: https://docs.flatpak.org/en/latest/
[using flatpak]: https://docs.flatpak.org/en/latest/using-flatpak.html

[how to clean up flatpak apps to clear disk space]: https://www.debugpoint.com/2021/10/clean-up-flatpak/
