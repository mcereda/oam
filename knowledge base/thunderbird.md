# Mozilla Thunderbird

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Profiles](#profiles)
   1. [Profile manager](#profile-manager)
   1. [Backing up profiles](#backing-up-profiles)
   1. [Restoring profiles from backups](#restoring-profiles-from-backups)
1. [Sources](#sources)

## TL;DR

## Profiles

Sets of files where Thunderbird saves personal information such as messages, passwords and user preferences.<br/>
One can have multiple profiles, each containing a separate set of user information.

The Profile Manager allows to create, remove, rename, and switch profiles. 

### Profile manager

When Thunderbird is open:

1. Open the hamburger menu on the top right, or look at the menu bar.
1. Choose _Help_ > _Troubleshooting Information_.
1. On the page that opens, click the _about:profiles_ link.

When Thunderbird is closed:

```sh
/Applications/Thunderbird.app/Contents/MacOS/thunderbird-bin --ProfileManager
${HOME}/Applications/Thunderbird.app/Contents/MacOS/thunderbird-bin -P
```

### Backing up profiles

1. Close Thunderbird if it is open.
1. Copy the profile folder to another location:
   ```sh
   cp -a "${HOME}/Library/Thunderbird/Profiles/we12yhij.default" "/Backup/Thunderbird/we12yhij.default"
   ```

### Restoring profiles from backups

1. Close Thunderbird if it is open.
1. If the existing profile folder and the profile backup folder have the same name, replace the existing profile folder with the profile backup folder:
   ```sh
   rm -fr "${HOME}/Library/Thunderbird/Profiles/we12yhij.default"
   cp -a "/Backup/Thunderbird/we12yhij.default" "${HOME}/Library/Thunderbird/Profiles/we12yhij.default"
   ```
   > Important: The profile folder names must match exactly for this to work, including the random string of 8 characters.
1. If the profile folder names do not match, or to move or restore a profile to a different location:
   1. Use the Profile Manager to create a new profile in the desired location, then exit the Profile Manager.
   1. Open the profile's backup folder.
   1. Copy **the entire contents** of the profile's backup folder.<br/>
      This includes the `mimeTypes.rdf`, `prefs.js` and the other files.
   1. Locate and open the new profile folder.
   1. Paste the copied contents into the new profile's folder.<br/>
      Overwrite existing files of the same name.
   1. Open up the `profiles.ini` file in the application data folder in a text editor.
      ```sh
      vim "${HOME}/Library/Thunderbird/profiles.ini"
      ```
   1. Check the `Path=` line for the profile is correct.
1. Start Thunderbird.

## Sources

- [profile manager create and remove thunderbird profiles]
- [Profiles - Where Thunderbird stores your messages and other user data]

<!--
  References
  -->

<!-- Upstream -->
[profile manager create and remove thunderbird profiles]: https://support.mozilla.org/en-US/kb/profile-manager-create-and-remove-thunderbird-profiles#
[profiles - where thunderbird stores your messages and other user data]: https://support.mozilla.org/en-US/kb/profiles-where-thunderbird-stores-user-data#
