# Mac OS X <!-- omit in toc -->

- [TL;DR](#tldr)
- [Xcode CLI tools](#xcode-cli-tools)
  - [Headless installation](#headless-installation)
  - [Upgrade](#upgrade)
- [Hidden settings](#hidden-settings)
- [Resize an image from CLI](#resize-an-image-from-cli)
- [Boot keys cheatsheet](#boot-keys-cheatsheet)
- [Update from CLI](#update-from-cli)
- [Keychain access from CLI](#keychain-access-from-cli)
- [Further readings](#further-readings)

## TL;DR

```shell
# install a .pkg file from cli
# target needs to be a device, not a path
installer -pkg /path/to/non-root-package.pkg -target CurrentUserHomeDirectory
sudo installer -pkg /path/to/root-needed-package.pkg -target /

# install xcode cli tools
xcode-select --install

# list all available updates
softwareupdate --list --all

# install all recommended updates agreeing to software license agreement without interaction and automatically restart if required
softwareupdate --install --recommended --restart --agree-to-license

# download (but not install) recommended updates
softwareupdate --download --recommended

# add a password to the default keychain
# the password needs to be left last
security add-generic-password -a johnny -s github -w 'b.good'

# add a password to the default keychain giving it some optional data
security add-generic-password -a johnny -s github -l work -j 'my key for work' -w 'b.good'

# update a passwork value
security add-generic-password -a johnny -s github -l work -U -w 'new-pass'

# print a password to stdout
security find-generic-password -w -a johnny -s github
security find-generic-password -w -l work
security find-generic-password -w -l work -s github

# delete a password from the default keychain
security delete-generic-password -a johnny -s github

# get the host's bonjour name
scutil --get LocalHostName
/usr/libexec/PlistBuddy -c "Print :System:Network:HostNames:LocalHostName" /Library/Preferences/SystemConfiguration/preferences.plist

# get the host's netbios name
defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName
/usr/libexec/PlistBuddy -c "Print :NetBIOSName" /Library/Preferences/SystemConfiguration/com.apple.smb.server.plist

# get the host's computer name
scutil --get ComputerName
/usr/libexec/PlistBuddy -c "Print :System:System:ComputerName" /Library/Preferences/SystemConfiguration/preferences.plist
```

## Xcode CLI tools

```shell
xcode-select --install
```

### Headless installation

In CLI:

1. prompt the `softwareupdate` utility to list the Command Line Tools

   ```sh
   touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
   ```

1. get their label

   ```sh
   export cli_tools_label="$(/usr/sbin/softwareupdate -l \
   | grep -B 1 -E 'Command Line Tools' \
   | awk -F'*' '/^ *\\*/ {print $2}' \
   | sed -e 's/^ *Label: //' -e 's/^ *//' \
   | sort -V \
   | tail -n1)"
   ```

1. install them

   ```sh
   /usr/sbin/softwareupdate -i ${cli_tools_label.stdout}
   ```

As Ansible task:

```yaml
- name: Check Command Line Tools are avilable
  command: xcode-select --print-path
  ignore_errors: true
  register: cli_tools_check
- name: Trying headless installing command line tools
  when: cli_tools_check is failed
  block:
  - name: Prompt the 'softwareupdate' utility to list the Command Line Tools
    file:
      path: /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
      state: touch
  - name: Get CLI tools label
    shell: >-
      /usr/sbin/softwareupdate -l
      | grep -B 1 -E 'Command Line Tools'
      | awk -F'*' '/^ *\\*/ {print $2}'
      | sed -e 's/^ *Label: //' -e 's/^ *//'
      | sort -V
      | tail -n1
    register: cli_tools_label
  - name: Install CLI tools
    command: /usr/sbin/softwareupdate -i '{{cli_tools_label.stdout}}'
    register: headless_cli_tools_installation
  - name: Fail with error
    when: headless_cli_tools_installation is failed
    fail:
      msg: Command Line Tools are not installed. Please execute 'xcode-select --install' in a terminal and accept the license first
```

### Upgrade

See [How to update Xcode from command line] for details.

```shell
# remove and reinstall
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

## Hidden settings

> **Note:** once set something, you'll probably need to restart the dock with `killall Dock`

```shell
# show hidden apps indicators in the dock
defaults write com.apple.dock showhidden -bool TRUE

# reset changes to the dock
defaults delete com.apple.dock

# change the number of columns and rows in the springboard
defaults write com.apple.dock springboard-columns -int 9
defaults write com.apple.dock springboard-rows -int 7

# reset changes to the launchpad
defaults delete com.apple.dock springboard-rows
defaults delete com.apple.dock springboard-columns
defaults write com.apple.dock ResetLaunchPad -bool TRUE
```

## Resize an image from CLI

Note:

* edits the input image
* `-Z` retains ratio

```shell
sips -Z 1000 Downloads/IMG_20190527_013903.jpg
```

## Boot keys cheatsheet

> only available for Intel based Macs

To use any of these key combinations, press and hold the keys immediately after pressing the power button to turn on your Mac, or after your Mac begins to restart. Keep holding until the described behavior occurs.

Combination | Behaviour
---|---
`⌥ Option` or `Alt` | Start to _Startup Manager_, which allows you to choose other available startup disks or volumes. If your Mac is using a firmware password, you're prompted to enter the password
`⌥ Option` + `⌘ Command` + `P` + `R` | Reset the NVRAM or PRAM. If your Mac is using a firmware password, it ignores this key combination or starts up from _Recovery_
`⇧ Shift` | Start in _safe_ mode. Disabled when using a firmware password
`⌘ Command` + `R` | Start from the built-in _Recovery_ system
`⌥ Option` + `⌘ Command` + `R` or `⇧ Shift` + `⌥ Option` + `⌘ Command` + `R` | Start from _Recovery_ over the Internet. It installs different versions of macOS, depending on the key combination you use while starting up. If your Mac is using a firmware password, you're prompted to enter the password
`⏏ Eject` or `F12` or `mouse button` or `trackpad button` | Eject a removable media, such as an optical disc. Disabled when using a firmware password
`T` | Start in _target disk_ mode. Disabled when using a firmware password
`⌘ Command` + `V` | Start in verbose mode. Disabled when using a firmware password
`D` | Start to _Apple Diagnostics_
`⌥ Option` + `D` | Start to _Apple Diagnostics_ over the Internet. Disabled when using a firmware password
`N` | Start from a NetBoot server, if your Mac supports network startup volumes. Disabled when using a firmware password
`⌥ Option` + `N` | Start from a NetBoot server and use the default boot image on it. Disabled when using a firmware password
`⌘ Command` + `S` | Start in _single-user_ mode. Disabled in macOS Mojave or later, or when using a firmware password

## Update from CLI

```shell
# list all available updates
softwareupdate --list --all

# install all recommended updates agreeing to software license agreement without interaction and automatically restart if required
softwareupdate --install --recommended --restart --agree-to-license

# download (but not install) recommended updates
softwareupdate --download --recommended
```

## Keychain access from CLI

Save a password with the following settings:

- user (a.k.a. _account_): `johnny`
- password: `b.good`
- service name: `github`
- \[optional] entry name (a.k.a. _label_): `work`; if not given, the service name will be used
- \[optional] comment: `my key for work`; if not given, it will be left blank

> the password's value needs to be given **last**

```shell
# add the password to the default keychain
security add-generic-password -a johnny -s github -w 'b.good'
# also give it some optional data
security add-generic-password -a johnny -s github -l work -j 'my key for work' -w 'b.good'
# update the passwork value
security add-generic-password -a johnny -s github -l work -U -w 'new-pass'

# print the above password to stdout
security find-generic-password -w -a johnny -s github
security find-generic-password -w -l work
security find-generic-password -w -l work -s github

# delete it
security delete-generic-password -a johnny -s github
```

## Further readings

- [Boot a Mac from USB Drive] on [WikiHow]
- [Mac startup key combinations] on [Apple's support site]
- [Xcode Command Line Tools Installation FAQ]
- [How to update Xcode from command line]
- [Command line access to the Mac keychain]
- [Installing .pkg with terminal?]
- [Using Terminal to Find Your Mac's Network Name]

[boot a mac from usb drive]: https://www.wikihow.com/Boot-a-Mac-from-USB-Drive
[command line access to the mac keychain]: https://blog.koehntopp.info/2017/01/26/command-line-access-to-the-mac-keychain.html
[how to update xcode from command line]: https://stackoverflow.com/questions/34617452/how-to-update-xcode-from-command-line#34617930
[installing .pkg with terminal?]: https://apple.stackexchange.com/questions/72226/installing-pkg-with-terminal#394976
[mac startup key combinations]: https://support.apple.com/en-us/HT201255
[using terminal to find your mac's network name]: https://www.tech-otaku.com/networking/using-terminal-find-your-macs-network-name/
[xcode command line tools installation faq]: https://www.godo.dev/tutorials/xcode-command-line-tools-installation-faq

[apple's support site]: https://support.apple.com
[wikihow]: https://www.wikihow.com
