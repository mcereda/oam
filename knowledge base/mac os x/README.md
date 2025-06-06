# Mac OS X

1. [TL;DR](#tldr)
1. [Taking screenshots](#taking-screenshots)
1. [Record the screen](#record-the-screen)
1. [Hidden settings](#hidden-settings)
   1. [Prevent Apple silicon laptops from turning on when opening their lid or connecting to power](#prevent-apple-silicon-laptops-from-turning-on-when-opening-their-lid-or-connecting-to-power)
1. [Image manipulation](#image-manipulation)
1. [Resize PDF files](#resize-pdf-files)
1. [Manage tags](#manage-tags)
1. [Update the OS from CLI](#update-the-os-from-cli)
1. [Keychain access from CLI](#keychain-access-from-cli)
1. [Mount an NFS share](#mount-an-nfs-share)
1. [Use TouchID to authenticate in the terminal](#use-touchid-to-authenticate-in-the-terminal)
    1. [Fix iTerm2](#fix-iterm2)
1. [Create custom DNS resolvers](#create-custom-dns-resolvers)
1. [Remap the Home and End keys](#remap-the-home-and-end-keys)
1. [Xcode CLI tools](#xcode-cli-tools)
    1. [Headless installation](#headless-installation)
    1. [Removal](#removal)
    1. [Upgrade](#upgrade)
1. [Apps of interest](#apps-of-interest)
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
caffeinate -dis
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

# List network interfaces.
ifconfig
networksetup -listallnetworkservices
networksetup -listallhardwareports

# Get information about network interfaces.
networksetup -getinfo 'Wi-Fi'
ipconfig getoption 'en0' 'domain_name_server'
ipconfig getoption 'en0' 'subnet_mask'

# Clear the DNS cache.
sudo dscacheutil -flushcache; sudo killall -HUP 'mDNSResponder'

# Resolve names.
dscacheutil -q 'host' -a 'name' 'hostname.or.fqdn'
dscacheutil -q 'host' -a 'name' '192.168.1.35'
dscacheutil -q 'host' -a 'name' 'gitlab.lan'


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

# Get the DNS configuration.
scutil --dns

# Get the proxy configuration.
scutil --proxy

# Get network information.
scutil --nwi


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


# Get information about users.
dscl '.' -read "/Users/$USER" 'UserShell'


# Bypass Gatekeeper for currently installed versions.
xattr -c '/path/to/app.app'

# Bypass Gatekeeper for all versions of apps.
xattr -d 'com.apple.quarantine' '/path/to/app.app'
xattr -dr 'com.apple.quarantine' '/path/to/directory'


# Install Rosetta
# Very difficult to remove, once installed
softwareupdate --install-rosetta --agree-to-license
```

## Taking screenshots

Shortcuts:

| Combination               | Effect                                                                                                                            |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `command` + `shift` + `3` | Takes a picture of one's entire screen. If using multiple screens, it will create an image for each.                              |
| `command` + `shift` + `4` | Allows to select an area on the screen to take a picture of, and it will create one image of the area one selected.               |
| `command` + `shift` + `5` | Brings up a tool that allows you to do all the above things as well as creating videos (with audio) of all or part of the screen. |

In the case of the first 2 options one can also hold the `control` key (e.g.: `command` + `shift` + `control` + `3`) to
send the screenshot to the clipboard instead.

## Record the screen

Use Quicktime Player to capture an area or the full screen by opening the application and selecting
`New Screen Recording` under the `File` menu, or by pressing `command` + `control` + `n`.

## Hidden settings

See the [`defaults`][defaults] command.

### Prevent Apple silicon laptops from turning on when opening their lid or connecting to power

Mac laptops with Apple silicon automatically turn on and start up when one opens their lid or connects them to power.

From macOS Sequoia 15, one can change this behavior.<br/>
This will **not** affect one's ability to use the keyboard or trackpad to turn on the Mac.

<details style="padding: 0 0 0 1em">
  <summary>Prevent startup when opening the lid or connecting to power</summary>

```sh
sudo nvram BootPreference=%00
```

</details>
<details style="padding: 0 0 0 1em">
  <summary>Prevent startup only when opening the lid</summary>

```sh
sudo nvram BootPreference=%01
```

</details>
<details style="padding: 0 0 1em 1em">
  <summary>Prevent startup only when connecting to power</summary>

```sh
sudo nvram BootPreference=%02
```

</details>

Undo any of the previous commands and reenable automatic startup when opening the lid or connecting to power:

```sh
sudo nvram -d BootPreference
```

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

Alternatively, check [ImageMagick] or [Ghostscript] out.

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

> This file is normally read-only, so saving your changes may require you to force the save (e.g. vim will require the
> use of `wq!` when saving).

### Fix iTerm2

iTerm2 from version 3.2.8 comes with a _reattach_ advanced feature which is incompatible with the addition of the
`pam_tid.so` module alone.

One can either:

- Disable the feature.<br/>
  iTerm2 > Preferences > Advanced > (Goto the Session heading) > _Allow sessions to survive logging out and back in_.
- Install and enable the `pam_reattach.so` module as _optional_ to `/etc/pam.d/sudo`:

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

  > When the module is not installed in `/usr/lib/pam` or `/usr/local/lib/pam` (e.g. on M1 Macs where Homebrew is
  > installed in `/opt/homebrew`), one must specify the **full** path to the module in the PAM service file.

## Create custom DNS resolvers

Refer [macOS: Using Custom DNS Resolvers].

Avoid adding custom DNS servers to `/etc/resolv.conf` as it often gets overwritten or otherwise edited by VPN clients
and such.

Instead:

1. Create the `/etc/resolver/` folder.
1. Inside that folder, create new files with the name of the domains one wants custom DNS settings for<br/>
   In this example, `lab.local`.
1. Edit those files by adding one's custom domain, search path and nameservers:

   ```plaintext
   domain lab.local
   search lab.local
   nameserver 192.168.1.254
   nameserver 192.168.1.1
   ```

1. Force a DNS refresh:

   ```sh
   sudo dscacheutil -flushcache; sudo killall -HUP 'mDNSResponder'
   ```

1. Verify the new DNS settings are in place:

   ```sh
   scutil --dns | grep -C '3' '192.168.1.254'
   ```

1. Check that name resolution works:

   ```sh
   dscacheutil -q 'host' -a 'name' '192.168.1.35'
   dscacheutil -q 'host' -a 'name' 'gitlab.lan'
   ```

## Remap the Home and End keys

Refer [Remap Home and End Keys?] and [trusktr's default keybindings].

```sh
mkdir -p "$HOME/Library/KeyBindings"
cat <<-EOF | tee "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
{
  /* Remap Home and End keys to act primarily on lines */
  "\UF729" = "moveToBeginningOfLine:"; /* Home */
  "\UF72B" = "moveToEndOfLine:"; /* End */
  "$\UF729" = "moveToBeginningOfLineAndModifySelection:"; /* Shift + Home */
  "$\UF72B" = "moveToEndOfLineAndModifySelection:"; /* Shift + End */
  "^\UF729" = "moveToBeginningOfDocument:"; /* Ctrl + Home */
  "^\UF72B" = "moveToEndOfDocument:"; /* Ctrl + End */
  "$^\UF729" = "moveToBeginningOfDocumentAndModifySelection:"; /* Shift + Ctrl + Home */
  "$^\UF72B" = "moveToEndOfDocumentAndModifySelection:"; /* Shift + Ctrl + End */
}
EOF
```

## Xcode CLI tools

```sh
xcode-select --install
```

The tools will be installed into `/Library/Developer/CommandLineTools` by default, with the binaries being available at
`$(xcode-select -p)/usr/bin/`.

### Headless installation

```sh
# Force the `softwareupdate` utility to list the Command Line Tools.
touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

# Get their label.
CLI_TOOLS_LABEL="$(\
  /usr/sbin/softwareupdate -l \
  | grep -B 1 -E 'Command Line Tools' \
  | awk -F'*' '/^ *\\*/ {print $2}' \
  | sed -e 's/^ *Label: //' -e 's/^ *//' \
  | sort -V \
  | tail -n1 \
)"

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

## Apps of interest

| Name                                                                                                          | Description                                                              |
| ------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| [BlueSnooze](https://github.com/odlp/bluesnooze)                                                              | Prevents your sleeping computer from connecting to Bluetooth accessories |
| [Clocker](https://apps.apple.com/en/app/clocker/id1056643111)                                                 | Menu bar timezone tracker and compact calendar                           |
| [iBar - menubar icon control tool](https://apps.apple.com/en/app/ibar-menubar-icon-control-tool/id6443843900) | Hide and show menu bar icons                                             |
| [Itsycal](https://www.mowglii.com/itsycal/)                                                                   | Menu bar calendar                                                        |
| [KeepingYouAwake](https://keepingyouawake.app/)                                                               | Prevent the mac from sleeping                                            |
| [KeyboardCleanTool](https://folivora.ai/keyboardcleantool)                                                    | Blocks all Keyboard and TouchBar input                                   |
| [Liuhai - hide topnotch](https://apps.apple.com/en/app/liuhai-hide-topnotch/id1592293770)                     | Hide the annoying notch on laptops                                       |
| [Maccy](https://maccy.app/)                                                                                   | Clipboard manager                                                        |
| [MonitorControl](https://github.com/MonitorControl/MonitorControl)                                            | Tool to control external monitor brightness & volume                     |
| [Mos](https://mos.caldis.me/)                                                                                 | Smooths scrolling and set mouse scroll directions independently          |
| [Rectangle](https://rectangleapp.com/)                                                                        | Move and resize windows in macOS using keyboard shortcuts or snap areas  |

## Boot keys cheatsheet

> Only available on Intel based Macs.

To use any of these key combinations, press and hold the keys immediately after pressing the power button to turn on
your Mac, or after your Mac begins to restart. Keep holding until the described behavior occurs.

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
- [macOS: Using Custom DNS Resolvers]
- [macOS tools and tips]
- [List all network hardware from command line in Mac OS]
- [Network warrior: how to use macOS network utilities]
- [Remap Home and End Keys?]
- [trusktr's default keybindings]
- [Improve docker volume performance on MacOS with a RAM disk]
- [Prevent a Mac laptop from turning on when opening its lid or connecting to power]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[defaults]: defaults.md
[ghostscript]: ../ghostscript.md
[imagemagick]: ../imagemagick.md
[jdberry/tag]: tag.md
[little snitch]: little%20snitch.md
[macports]: macports.md
[openssl-osx-ca]: openssl-osx-ca.md
[sips]: sips.md
[tag]: tag.md
[time machine]: time%20machine.md
[xattr]: xattr.md

<!-- Upstream -->
[compress a pdf in preview on mac]: https://support.apple.com/guide/preview/compress-a-pdf-prvw1509/mac
[mac startup key combinations]: https://support.apple.com/en-us/HT201255
[prevent a mac laptop from turning on when opening its lid or connecting to power]: https://support.apple.com/en-us/120622
[resize, rotate, or flip an image in preview on mac]: https://support.apple.com/guide/preview/resize-rotate-or-flip-an-image-prvw2015/11.0/mac/13.0

<!-- Others -->
[boot a mac from usb drive]: https://www.wikihow.com/Boot-a-Mac-from-USB-Drive
[caffeinate your mac]: https://www.theapplegeek.co.uk/blog/caffeinate
[can touch id for the mac touch bar authenticate sudo users and admin privileges?]: https://apple.stackexchange.com/questions/259093/can-touch-id-for-the-mac-touch-bar-authenticate-sudo-users-and-admin-privileges#306324
[command line access to the mac keychain]: https://blog.koehntopp.info/2017/01/26/command-line-access-to-the-mac-keychain.html
[how to clear dns cache in macos ventura & macos monterey]: https://osxdaily.com/2022/11/21/how-clear-dns-cache-macos-ventura-monterey/
[how to update xcode from command line]: https://stackoverflow.com/questions/34617452/how-to-update-xcode-from-command-line#34617930
[improve docker volume performance on macos with a ram disk]: https://thoughts.theden.sh/posts/docker-ramdisk-macos-benchmark/
[installing .pkg with terminal?]: https://apple.stackexchange.com/questions/72226/installing-pkg-with-terminal#394976
[launchctl man page]: https://www.unix.com/man-page/osx/1/launchctl
[list all network hardware from command line in mac os]: https://osxdaily.com/2014/09/03/list-all-network-hardware-from-the-command-line-in-os-x/
[list of xcode command line tools]: https://mac.install.guide/commandlinetools/8.html
[macos default values command reference]: https://github.com/kevinSuttle/macOS-Defaults/blob/master/REFERENCE.md
[macos network quality tool]: https://www.theapplegeek.co.uk/blog/networkquality
[macos tools and tips]: https://handbook.gitlab.com/handbook/tools-and-tips/mac/
[macos: using custom dns resolvers]: https://vninja.net/2020/02/06/macos-custom-dns-resolvers/
[mdls]: https://ss64.com/osx/mdls.html
[network warrior: how to use macos network utilities]: https://medium.com/macoclock/network-warrior-how-to-use-macos-network-utilities-63c88f490ba0
[pam_reattach]: https://github.com/fabianishere/pam_reattach
[remap home and end keys?]: https://discussions.apple.com/thread/251108215
[tagging files from the macos command line]: https://brettterpstra.com/2017/08/22/tagging-files-from-the-command-line/
[trusktr's default keybindings]: https://gist.github.com/trusktr/1e5e516df4e8032cbc3d
[using terminal to find your mac's network name]: https://www.tech-otaku.com/networking/using-terminal-find-your-macs-network-name/
[who is listening on a given tcp port on mac os x?]: https://stackoverflow.com/questions/4421633/who-is-listening-on-a-given-tcp-port-on-mac-os-x
[xcode command line tools installation faq]: https://www.godo.dev/tutorials/xcode-command-line-tools-installation-faq
