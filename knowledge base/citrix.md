# Citrix

## TL;DR

```sh
# Disable autostart on macOS.
find /Library/LaunchAgents /Library/LaunchDaemons \
  -iname "*.citrix.*.plist" \
  -exec sudo -p 'sudo password: ' mv -fv {} {}.backup ';'
```
