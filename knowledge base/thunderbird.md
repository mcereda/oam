# Mozilla Thunderbird

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Profiles](#profiles)
   1. [Profile manager](#profile-manager)
   1. [Backing up profiles](#backing-up-profiles)
   1. [Restoring profiles from backups](#restoring-profiles-from-backups)
1. [Troubleshooting](#troubleshooting)
   1. [Rebuild the Global Database for a Profile](#rebuild-the-global-database-for-a-profile)
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
      vim "${THUNDERBIRD_DATA_DIR}/profiles.ini"
      ```
   1. Check the `Path=` line for the profile is correct.
1. Start Thunderbird.

## Troubleshooting

### Rebuild the Global Database for a Profile

The Global Database is the indexing system that enables Thunderbird to search messages.<br/>
Rebuilding the Global Database re-indexes messages and address book cards. Newsgroup messages are **not** indexed.

Reasons for rebuilding the Global Database include:

- The database may have been corrupted.
- The search index may not be functioning correctly, such as displaying blank results or performing poorly.
- The database is too big and needs to be reduced in size.
- The Global Database file becomes fragmented, which reduces index performance.

Rebuilding the database will **not** automatically reduce the size of the index.<br/>
It will only shrink if there are fewer messages to index since it was last updated, which can be accomplished by deleting messages or disabling message sync for an account or folder.

Steps to rebuild the Global Database:

1. Quit Thunderbird.
1. Delete the `global-messages-db.sqlite` file in the Thunderbird Profile you want to rebuild the index for.
   ```sh
   rm "${THUNDERBIRD_DATA_DIR}/Profiles/we12yhij.default/global-messages-db.sqlite"
   ```
1. Start Thunderbird.

The re-indexing process will start automatically.<br/>
Depending on the number of messages, it might take some time for the indexing to complete; performance might be affected, and the search will return only partial results or even no results until the indexing is complete.

The indexing progress can be monitored through _Tools_ > _Activity Manager_.

## Sources

- [Profile manager - create and remove thunderbird profiles]
- [Profiles - Where Thunderbird stores your messages and other user data]
- [Rebuilding the global database]
- [Arch Wiki]

<!--
  References
  -->

<!-- Upstream -->
[profile manager - create and remove thunderbird profiles]: https://support.mozilla.org/en-US/kb/profile-manager-create-and-remove-thunderbird-profiles#
[profiles - where thunderbird stores your messages and other user data]: https://support.mozilla.org/en-US/kb/profiles-where-thunderbird-stores-user-data#
[rebuilding the global database]: https://support.mozilla.org/en-US/kb/rebuilding-global-database#

<!-- Others -->
[arch wiki]: https://wiki.archlinux.org/title/thunderbird
