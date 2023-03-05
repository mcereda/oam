# Mac OS X <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Xcode CLI tools](#xcode-cli-tools)
   1. [Headless installation](#headless-installation)
   1. [Removal](#removal)
   1. [Upgrade](#upgrade)
1. [Hidden settings](#hidden-settings)
1. [Resize an image from CLI](#resize-an-image-from-cli)
1. [Boot keys cheatsheet](#boot-keys-cheatsheet)
1. [Update the OS from CLI](#update-the-os-from-cli)
1. [Keychain access from CLI](#keychain-access-from-cli)
1. [Use TouchID to authenticate in the terminal](#use-touchid-to-authenticate-in-the-terminal)
   1. [Fix iTerm2](#fix-iterm2)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Keep the system awake.
caffeinate
caffeinate -t 600

# Do a network speed test.
networkquality -sv

# Install Xcode CLI tools.
xcode-select --install

# Show Xcode tools's path.
xcode-select -p

# Remove Xcode tools.
sudo rm -rf $(xcode-select -p)

# List all available updates.
softwareupdate --list --all

# Install all recommended updates, agreeing to software license agreement
# without interaction, and automatically restart if required.
softwareupdate --install --recommended --restart --agree-to-license

# Download (but not install) recommended updates.
softwareupdate --download --recommended

# Install a .pkg file from CLI.
# 'target' needs to be a device, not a path.
installer -pkg /path/to/non-root-package.pkg -target CurrentUserHomeDirectory
sudo installer -pkg /path/to/root-needed-package.pkg -target /

# Add a password to the default keychain.
# The password needs to be left last.
security add-generic-password -a johnny -s github -w 'b.good'

# Add a password to the default keychain giving it some optional data.
security add-generic-password -a johnny -s github -l work \
  -j 'my key for work' -w 'b.good'

# Update passwords' value.
security add-generic-password -a johnny -s github -l work -U -w 'new-pass'

# Print passwords to stdout.
security find-generic-password -w -a johnny -s github
security find-generic-password -w -l work
security find-generic-password -w -l work -s github

# Delete a password from the default keychain.
security delete-generic-password -a johnny -s github

# Get the host's bonjour name.
scutil --get LocalHostName
/usr/libexec/PlistBuddy -c "Print :System:Network:HostNames:LocalHostName" \
  /Library/Preferences/SystemConfiguration/preferences.plist

# Get the host's netbios name.
defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName
/usr/libexec/PlistBuddy -c "Print :NetBIOSName" \
  /Library/Preferences/SystemConfiguration/com.apple.smb.server.plist

# Get the host's computer name.
scutil --get ComputerName
/usr/libexec/PlistBuddy -c "Print :System:System:ComputerName" \
  /Library/Preferences/SystemConfiguration/preferences.plist

# Get environment variables from inside launchd.
launchctl getenv 'key'
launchctl export

# Set environment variables inside of launchd.
launchctl setenv 'key' 'value'
launchctl unsetenv 'key' 'value'

# List all loaded jobs.
launchctl list

# List Mach bootstrap services only.
launchctl bslist
launchctl bstree

# Start jobs.
launchctl start 'job_label'

# Stop jobs.
launchctl stop 'job_label'
```

## Xcode CLI tools

```sh
xcode-select --install
```

The tools will be installed into `/Library/Developer/CommandLineTools` by default, with the binaries being available at `$(xcode-select -p)/usr/bin/`.

### Headless installation

```sh
# Force the `softwareupdate` utility to list the Command Line Tools.
touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

# Get their label.
CLI_TOOLS_LABEL="$(/usr/sbin/softwareupdate -l \
 | grep -B 1 -E 'Command Line Tools' \
 | awk -F'*' '/^ *\\*/ {print $2}' \
 | sed -e 's/^ *Label: //' -e 's/^ *//' \
 | sort -V \
 | tail -n1)"

# Install them.
/usr/sbin/softwareupdate -i --agree-to-license "$CLI_TOOLS_LABEL"
```

### Removal

```sh
sudo rm -rf "$(xcode-select -p)"
sudo rm -rf '/Library/Developer/CommandLineTools'
```

### Upgrade

See [How to update Xcode from command line] for details.

```sh
# Remove and reinstall.
sudo rm -rf "$(xcode-select -p)"
xcode-select --install
```

## Hidden settings

> **Note:** once set something, you'll probably need to restart the dock with `killall Dock`

```sh
# Show hidden apps indicators in the dock.
defaults write com.apple.dock showhidden -bool TRUE

# Reset changes to the dock.
defaults delete com.apple.dock

# Change the number of columns and rows in the springboard.
defaults write com.apple.dock springboard-columns -int 9
defaults write com.apple.dock springboard-rows -int 7

# Reset changes to the launchpad.
defaults delete com.apple.dock springboard-rows
defaults delete com.apple.dock springboard-columns
defaults write com.apple.dock ResetLaunchPad -bool TRUE

# Force Finder to always display hidden files.
defaults write com.apple.finder AppleShowAllFiles TRUE
```

## Resize an image from CLI

```sh
# Retain ratio.
# Save as different file.
sips -Z '1000' -o 'resized.jpg' 'IMG_20190527_013903.jpg'
```

## Boot keys cheatsheet

> Only available on Intel based Macs.

To use any of these key combinations, press and hold the keys immediately after pressing the power button to turn on your Mac, or after your Mac begins to restart. Keep holding until the described behavior occurs.

| Combination                                                                  | Behaviour                                                                                                                                                                                                                     |
| ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `⌥ Option` or `Alt`                                                          | Start to _Startup Manager_, which allows you to choose other available startup disks or volumes. If your Mac is using a firmware password, you're prompted to enter the password                                              |
| `⌥ Option` + `⌘ Command` + `P` + `R`                                         | Reset the NVRAM or PRAM. If your Mac is using a firmware password, it ignores this key combination or starts up from _Recovery_                                                                                               |
| `⇧ Shift`                                                                    | Start in _safe_ mode. Disabled when using a firmware password                                                                                                                                                                 |
| `⌘ Command` + `R`                                                            | Start from the built-in _Recovery_ system                                                                                                                                                                                     |
| `⌥ Option` + `⌘ Command` + `R` or `⇧ Shift` + `⌥ Option` + `⌘ Command` + `R` | Start from _Recovery_ over the Internet. It installs different versions of macOS, depending on the key combination you use while starting up. If your Mac is using a firmware password, you're prompted to enter the password |
| `⏏ Eject` or `F12` or `mouse button` or `trackpad button`                    | Eject a removable media, such as an optical disc. Disabled when using a firmware password                                                                                                                                     |
| `T`                                                                          | Start in _target disk_ mode. Disabled when using a firmware password                                                                                                                                                          |
| `⌘ Command` + `V`                                                            | Start in verbose mode. Disabled when using a firmware password                                                                                                                                                                |
| `D`                                                                          | Start to _Apple Diagnostics_                                                                                                                                                                                                  |
| `⌥ Option` + `D`                                                             | Start to _Apple Diagnostics_ over the Internet. Disabled when using a firmware password                                                                                                                                       |
| `N`                                                                          | Start from a NetBoot server, if your Mac supports network startup volumes. Disabled when using a firmware password                                                                                                            |
| `⌥ Option` + `N`                                                             | Start from a NetBoot server and use the default boot image on it. Disabled when using a firmware password                                                                                                                     |
| `⌘ Command` + `S`                                                            | Start in _single-user_ mode. Disabled in macOS Mojave or later, or when using a firmware password                                                                                                                             |

## Update the OS from CLI

```sh
# List all available updates.
softwareupdate --list --all

# Install all recommended updates.
# Agree to software license agreement without interaction.
# Automatically restart if required.
softwareupdate --install --recommended --restart --agree-to-license

# Download (but not install) recommended updates.
softwareupdate --download --recommended
```

## Keychain access from CLI

Save a password with the following settings:

- user (a.k.a. _account_): `johnny`
- password: `b.good`
- service name: `github`
- \[optional] entry name (a.k.a. _label_): `work`; if not given, the service name will be used
- \[optional] comment: `my key for work`; if not given, it will be left blank

> The password's value needs to be given **last**.

```sh
# Add the password to the default keychain.
security add-generic-password -a johnny -s github -w 'b.good'
# Also give it some optional data.
security add-generic-password -a johnny -s github -l work \
  -j 'my key for work' -w 'b.good'
# Update passwords' value.
security add-generic-password -a johnny -s github -l work -U -w 'new-pass'

# Print the above password to stdout.
security find-generic-password -w -a johnny -s github
security find-generic-password -w -l work
security find-generic-password -w -l work -s github

# Delete it.
security delete-generic-password -a johnny -s github
```

## Use TouchID to authenticate in the terminal

Add the `pam_tid.so` module as _sufficient_ to `/etc/pam.d/sudo`:

```diff
# sudo: auth account password session
+auth       sufficient     pam_tid.so
auth       sufficient     pam_smartcard.so
auth       required       pam_opendirectory.so
```

> This file is normally read-only, so saving your changes may require you to force the save (e.g. vim will require the use of `wq!` when saving).

### Fix iTerm2

iTerm2 from version 3.2.8 comes with a _reattach_ advanced feature which is incompatible with the addition of the `pam_tid.so` module alone.

You can either:

- disable the feature: iTerm2 > Preferences > Advanced > (Goto the Session heading) > _Allow sessions to survive logging out and back in_
- install and enable the `pam_reattach.so` module as _optional_ to `/etc/pam.d/sudo`:

  ```sh
  # pick one
  brew install pam-reattach
  sudo port install pam-reattach
  ```

  ```diff
  # sudo: auth account password session
  +auth       optional       /opt/local/lib/pam/pam_reattach.so ignore_ssh
  +auth       sufficient     pam_tid.so
  auth       sufficient     pam_smartcard.so
  auth       required       pam_opendirectory.so
  ```

  > Note that when the module is not installed in `/usr/lib/pam` or `/usr/local/lib/pam` (e.g. on M1 Macs where Homebrew is installed in `/opt/homebrew`), you must specify the full path to the module in the PAM service file.

## Further readings

- [pam_reattach]
- [launchctl man page]

## Sources

- [Boot a Mac from USB Drive]
- [Mac startup key combinations]
- [Xcode Command Line Tools Installation FAQ]
- [How to update Xcode from command line]
- [Command line access to the Mac keychain]
- [Installing .pkg with terminal?]
- [Using Terminal to Find Your Mac's Network Name]
- [List of Xcode Command Line Tools]
- [Can Touch ID for the Mac Touch Bar authenticate sudo users and admin privileges?]
- [Caffeinate your Mac]
- [MacOS network quality tool]

<!-- project's references -->
[mac startup key combinations]: https://support.apple.com/en-us/HT201255

<!-- external references -->
[boot a mac from usb drive]: https://www.wikihow.com/Boot-a-Mac-from-USB-Drive
[caffeinate your mac]: https://www.theapplegeek.co.uk/blog/caffeinate
[can touch id for the mac touch bar authenticate sudo users and admin privileges?]: https://apple.stackexchange.com/questions/259093/can-touch-id-for-the-mac-touch-bar-authenticate-sudo-users-and-admin-privileges#306324
[command line access to the mac keychain]: https://blog.koehntopp.info/2017/01/26/command-line-access-to-the-mac-keychain.html
[how to update xcode from command line]: https://stackoverflow.com/questions/34617452/how-to-update-xcode-from-command-line#34617930
[installing .pkg with terminal?]: https://apple.stackexchange.com/questions/72226/installing-pkg-with-terminal#394976
[launchctl man page]: https://www.unix.com/man-page/osx/1/launchctl
[list of xcode command line tools]: https://mac.install.guide/commandlinetools/8.html
[macos network quality tool]: https://www.theapplegeek.co.uk/blog/networkquality
[pam_reattach]: https://github.com/fabianishere/pam_reattach
[using terminal to find your mac's network name]: https://www.tech-otaku.com/networking/using-terminal-find-your-macs-network-name/
[xcode command line tools installation faq]: https://www.godo.dev/tutorials/xcode-command-line-tools-installation-faq
