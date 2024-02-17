# Get users' login shell

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Works on Linux and Mac OS X.
# Tested with BASH, CSH, DASH, FISH, KSH, TCSH and ZSH.
finger "$USER" | grep 'Shell:' | awk '{print $NF}'

# Works on Linux.
# Tested with BASH.
getent passwd "$USER" | awk -F ':' '{print $NF}'
getent passwd "$USER" | cut -d ':' -f '7'

# Works on Linux.
# Does *not* work on Mac OS X because it uses Apple's OpenDirectory and only
# refers to '/etc/passwd' or '/private/etc/passwd' when in single user mode.
# Tested with BASH.
grep "$USER" '/etc/passwd' | awk -F ':' '{print $NF}'
grep "$USER" '/etc/passwd' | cut -d ':' -f '7'

# Works on Mac OS X.
# Does *not* work on systems without OpenDirectory.
# Tested with BASH, CSH, DASH, FISH, KSH, TCSH and ZSH.
dscl '.' -read "/Users/$USER" 'UserShell' | awk '{print $NF}'
dscl '.' -read "/Users/$USER" 'UserShell' | cut -d ' ' -f '2'
```

## Further readings

### Sources

- [Users don't appear in /etc/passwd on Mac OS X]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[users don't appear in /etc/passwd on mac os x]: https://superuser.com/questions/191330/users-dont-appear-in-etc-passwd-on-mac-os-x#1425510
