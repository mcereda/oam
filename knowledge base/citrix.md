# Citrix

## TL;DR

```sh
# Disable autostart on Mac OS X.
find /Library/LaunchAgents /Library/LaunchDaemons \
  -iname "*.citrix.*.plist" \
  -exec sudo -p 'sudo password: ' mv -fv {} {}.backup ';'
```
