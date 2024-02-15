# Mac OS X

1. [TL;DR](#tldr)
1. [Hidden settings](#hidden-settings)
1. [Image manipulation](#image-manipulation)
1. [Resize PDF files](#resize-pdf-files)
1. [Manage tags](#manage-tags)
1. [Update the OS from CLI](#update-the-os-from-cli)
1. [Keychain access from CLI](#keychain-access-from-cli)
1. [Mount an NFS share](#mount-an-nfs-share)
1. [Use TouchID to authenticate in the terminal](#use-touchid-to-authenticate-in-the-terminal)
   1. [Fix iTerm2](#fix-iterm2)
1. [Xcode CLI tools](#xcode-cli-tools)
    1. [Headless installation](#headless-installation)
    1. [Removal](#removal)
    1. [Upgrade](#upgrade)
1. [Boot keys cheatsheet](#boot-keys-cheatsheet)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

```sh
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


# Keep the system awake.
caffeinate
caffeinate -t '600'

# Perform network speed tests.
networkquality -sv

# List open ports.
netstat
netstat -n -p 'tcp'
lsof -n -i ':443'
sudo lsof -n -i 'TCP' -s 'TCP:LISTEN'

# Get the PID of processes using specific ports.
lsof -nt -i ':443'

# Clear the DNS cache.
sudo dscacheutil -flushcache; sudo killall -HUP 'mDNSResponder'


# Check NFS shares are available on the network.
showmount -e 'host'

# Mount NFS shares.
sudo mount -t 'nfs' 'host:/path/to/share' 'path/to/mount/point'
sudo mount -t 'nfs' -o 'rw,resvport' 'host:/path/to/share' 'path/to/mount/point'


# Install .pkg files from CLI.
# 'target' needs to be a *device*, not a path.
installer -pkg '/path/to/nonroot-package.pkg' -target 'CurrentUserHomeDirectory'
sudo installer -pkg '/path/to/root-needed-package.pkg' -target '/'


# Add passwords to the default keychain.
# The password needs to be left last.
security add-generic-password -a 'johnny' -s 'github' -w 'b.good'
security add-generic-password -a 'johnny' -s 'github' -l 'work' \
  -j 'my key for work' -w 'b.good'

# Update passwords' value.
security add-generic-password -a 'johnny' -s 'github' -l 'work' -U -w 'new-pass'

# Print passwords to stdout.
security find-generic-password -w -a 'johnny' -s 'github'
security find-generic-password -w -l 'work'
security find-generic-password -w -l 'work' -s 'github'

# Delete passwords from the default keychain.
security delete-generic-password -a 'johnny' -s 'github'


# Get the host's computer name.
scutil --get 'ComputerName'
/usr/libexec/PlistBuddy -c "Print :System:System:ComputerName" \
  '/Library/Preferences/SystemConfiguration/preferences.plist'

# Set the host's computer name.
scutil --set 'ComputerName' 'newComputerName'

# Get the host's bonjour name.
scutil --get 'LocalHostName'
/usr/libexec/PlistBuddy -c "Print :System:Network:HostNames:LocalHostName" \
  '/Library/Preferences/SystemConfiguration/preferences.plist'

# Get the host's bonjour name.
scutil --set 'LocalHostName' 'newLocalHostName'
scutil --set 'LocalHostName' \
  "$(defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName)"

# Get the host's netbios name.
defaults read '/Library/Preferences/SystemConfiguration/com.apple.smb.server' 'NetBIOSName'
/usr/libexec/PlistBuddy -c "Print :NetBIOSName" \
  '/Library/Preferences/SystemConfiguration/com.apple.smb.server.plist'


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


# Enable file trimming on SSD.
sudo trimforce enable
```

## Hidden settings

See the [`defaults`][defaults] command.

## Image manipulation

Use Preview to perform basic image manipulation through the GUI.<br/>
See [Resize, rotate, or flip an image in Preview on Mac].

See [`sips`][sips] for the command line utility shipping with OS X by default.<br/>
Install [ImageMagick] if you need something more powerful.

## Resize PDF files

In the Preview app:

1. Open the PDF file you want to compress.
1. Choose _File_ > _Export_.<br/>
   **Do not** choose _Export as PDF_.
1. Click the _Quartz Filter_ pop-up menu, then choose _Reduce File Size_.
1. Click the _Export_ button.

## Manage tags

Tags are stored both in a file's or folder's `com.apple.metadata:_kMDItemUserTags` extended attribute.

Avoid using the `xattr` tool, as it almost always returns the hex dump of a `plist` file, which needs to be converted:

```sh
$ xattr -px com.apple.metadata:_kMDItemUserTags 'path/to/file' \
| perl -wane 'print chr hex for @F' | plutil -p -
[
  0 => "test"
]
```

[`mdls`][mdls] returns a more readable output, but still is not really useful for other actions than read:

```sh
$ mdls -raw -name kMDItemUserTags 'path/to/file'
(
    test
)
```

See [jdberry/tag] for a more versatile command line utility.<br/>
See [Tagging files from the macOS command line] for more information.

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

## Mount an NFS share

1. Check the share is available on the network:

   ```sh
   showmount -e 'host'
   ```

1. Mount the share:

   - Using the CLI:

     ```sh
     mkdir -p 'path/to/mount/point'
     sudo mount -t 'nfs' 'host:/path/to/share' 'path/to/mount/point'
     sudo mount -t 'nfs' -o 'rw,resvport' 'host:/path/to/share' 'path/to/mount/point'
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

## Further readings

- [Time Machine]
- [`tag`][tag]
- [`sips`][sips]
- [`defaults`][defaults]
- [`pam_reattach`][pam_reattach]
- [`launchctl`'s man page][launchctl man page]
- [`mdls`][mdls]
- [`xattr`][xattr]
- [`macports`][macports]
- [`openssl-osx-ca`][openssl-osx-ca]
- [Little Snitch]
- [macOS default values command reference]

### Sources

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
- [How to Clear DNS Cache in MacOS Ventura & MacOS Monterey]
- [Compress a PDF in Preview on Mac]
- [Resize, rotate, or flip an image in Preview on Mac]
- [Who is listening on a given TCP port on Mac OS X?]
- [Tagging files from the macOS command line]

<!--
  References
  -->

<!-- Upstream -->
[compress a pdf in preview on mac]: https://support.apple.com/guide/preview/compress-a-pdf-prvw1509/mac
[mac startup key combinations]: https://support.apple.com/en-us/HT201255
[resize, rotate, or flip an image in preview on mac]: https://support.apple.com/guide/preview/resize-rotate-or-flip-an-image-prvw2015/11.0/mac/13.0

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[defaults]: defaults.md
[imagemagick]: ../imagemagick.md
[jdberry/tag]: tag.md
[little snitch]: little%20snitch.md
[macports]: macports.md
[openssl-osx-ca]: openssl-osx-ca.md
[sips]: sips.md
[tag]: tag.md
[time machine]: time%20machine.md
[xattr]: xattr.md

<!-- Others -->
[boot a mac from usb drive]: https://www.wikihow.com/Boot-a-Mac-from-USB-Drive
[caffeinate your mac]: https://www.theapplegeek.co.uk/blog/caffeinate
[can touch id for the mac touch bar authenticate sudo users and admin privileges?]: https://apple.stackexchange.com/questions/259093/can-touch-id-for-the-mac-touch-bar-authenticate-sudo-users-and-admin-privileges#306324
[command line access to the mac keychain]: https://blog.koehntopp.info/2017/01/26/command-line-access-to-the-mac-keychain.html
[how to clear dns cache in macos ventura & macos monterey]: https://osxdaily.com/2022/11/21/how-clear-dns-cache-macos-ventura-monterey/
[how to update xcode from command line]: https://stackoverflow.com/questions/34617452/how-to-update-xcode-from-command-line#34617930
[installing .pkg with terminal?]: https://apple.stackexchange.com/questions/72226/installing-pkg-with-terminal#394976
[launchctl man page]: https://www.unix.com/man-page/osx/1/launchctl
[list of xcode command line tools]: https://mac.install.guide/commandlinetools/8.html
[macos default values command reference]: https://github.com/kevinSuttle/macOS-Defaults/blob/master/REFERENCE.md
[macos network quality tool]: https://www.theapplegeek.co.uk/blog/networkquality
[mdls]: https://ss64.com/osx/mdls.html
[pam_reattach]: https://github.com/fabianishere/pam_reattach
[tagging files from the macos command line]: https://brettterpstra.com/2017/08/22/tagging-files-from-the-command-line/
[using terminal to find your mac's network name]: https://www.tech-otaku.com/networking/using-terminal-find-your-macs-network-name/
[who is listening on a given tcp port on mac os x?]: https://stackoverflow.com/questions/4421633/who-is-listening-on-a-given-tcp-port-on-mac-os-x
[xcode command line tools installation faq]: https://www.godo.dev/tutorials/xcode-command-line-tools-installation-faq
