# KDE

## TL;DR

```shell
# Get from '~/.config/kinfocenterrc' the current value for the 'MenuBar' key in
# the 'MainWindow' group.
kreadconfig5 --file kinfocenterrc --group MainWindow --key MenuBar

# Set into '~/.config/kdeglobals' a new value for the 'Show hidden files' key in
# the 'KFileDialog Settings' group.
kwriteconfig5 --file kdeglobals --group 'KFileDialog Settings' \
  --key 'Show hidden files' --type bool true
```

## Further readings

- [KDE Configuration Files]

[kde configuration files]: https://userbase.kde.org/KDE_System_Administration/Configuration_Files

## Sources

- [Gsettings-like tools for KDE]

[gsettings-like tools for kde]: https://askubuntu.com/questions/839647/gsettings-like-tools-for-kde
