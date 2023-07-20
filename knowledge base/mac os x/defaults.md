# Defaults

Allows users to read, write, and delete Mac OS X user defaults from a command-line shell.

Mac OS X applications and other programs use the defaults system to record user preferences and other information that must be maintained when the applications aren't running (such as default font for new documents, or the position of an Info panel).<br/>
Much of this information is accessible through an application's Preferences panel, but some of it can only be accessed using `defaults`.

User defaults belong to **domains**, which typically correspond to individual applications.<br/>
Each domain has a dictionary of keys and values representing its defaults. Keys are always strings, but values can be complex data structures comprising arrays, dictionaries, strings, and binary data. These data structures are stored as XML Property Lists.

The `NSGlobalDomain` domain is a special global domain shared by all applications, system services.<br/>
If a default isn't specified in the application's domain but is specified in NSGlobalDomain, then the application falls back to the value in NSGlobalDomain.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# List available domains.
defaults domains

# Read values.
# defaults read 'domain'
# defaults read 'domain' 'key'
defaults read 'com.apple.dock'
defaults read -app 'Docker' 'SUHasLaunchedBefore'
defaults read '/Library/Preferences/SystemConfiguration/com.apple.smb.server' 'NetBIOSName'

# Write or overwrite values.
# defaults write 'domain' 'key' 'value'
# defaults write 'domain' 'plist'
defaults write 'com.apple.dock' 'springboard-columns' -int '9'
defaults write -app 'DeSmuME' 'CoreControl_EnableCheats' -bool 'TRUE'
defaults write '/Users/user/Library/Preferences/org.raspberrypi.Imager' 'imagecustomization.keyboardLayout' 'us'

# Delete values.
# defaults delete 'domain'
# defaults delete 'domain' 'key'
defaults delete 'com.apple.dock' 'springboard-columns'
defaults write -app 'VLC'
```

## Further readings

- [`man` page][man page]
- [Mac OS X]

<!--
  References
  -->

<!-- Knowledge base -->
[mac os x]: README.md

<!-- Others -->
[man page]: https://ss64.com/osx/defaults.html
