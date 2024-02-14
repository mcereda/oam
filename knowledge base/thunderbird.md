# Mozilla Thunderbird

1. [TL;DR](#tldr)
1. [Profiles](#profiles)
   1. [Profile manager](#profile-manager)
   1. [Backing up profiles](#backing-up-profiles)
   1. [Restoring profiles from backups](#restoring-profiles-from-backups)
1. [Troubleshooting](#troubleshooting)
   1. [Create a dummy account](#create-a-dummy-account)
   1. [Convert an account's message store type from one file per folder (_mbox_) to one file per message (_maildir_)](#convert-an-accounts-message-store-type-from-one-file-per-folder-mbox-to-one-file-per-message-maildir)
   1. [Rebuild the Global Database for a Profile](#rebuild-the-global-database-for-a-profile)
   1. [You are already subscribed to this feed](#you-are-already-subscribed-to-this-feed)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

Default directories path:

| Directory | Linux                  | Mac OS X                                       | Windows                                  |
| --------- | ---------------------- | ---------------------------------------------- | ---------------------------------------- |
| Binaries  | `/usr/bin`             | `/Applications/Thunderbird.app/Contents/MacOS` | `C:\Program Files\Mozilla Thunderbird`   |
| Data      | `${HOME}/.thunderbird` | `${HOME}/Library/Thunderbird`                  | `%APPDATA%\Roaming\Thunderbird`          |
| Profiles  | `${HOME}/.thunderbird` | `${HOME}/Library/Thunderbird/Profiles`         | `%APPDATA%\Roaming\Thunderbird\Profiles` |

Add-ons:

| Add-on                                       | Description                                                |
| -------------------------------------------- | ---------------------------------------------------------- |
| [ImportExportTools NG][importexporttools-ng] | Tools to import/export messages and folders.               |
| [Remove Duplicate Messages][removedupes]     | Search and remove duplicate messages in your mail folders. |

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
${THUNDERBIRD_BIN_DIR}/thunderbird --ProfileManager
${THUNDERBIRD_BIN_DIR}/thunderbird-bin -P
```

### Backing up profiles

1. Close Thunderbird if it is open.
1. Copy the profile folder to another location:

   ```sh
   cp -a "${THUNDERBIRD_PROFILES_DIR}/we12yhij.default" "/Backup/Thunderbird/we12yhij.default"
   ```

### Restoring profiles from backups

1. Close Thunderbird if it is open.
1. If the existing profile folder and the profile backup folder have the same name, replace the existing profile folder with the profile backup folder:

   ```sh
   rm -fr "${THUNDERBIRD_PROFILES_DIR}/we12yhij.default"
   cp -a "/Backup/Thunderbird/we12yhij.default" "${THUNDERBIRD_PROFILES_DIR}/we12yhij.default"
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

### Create a dummy account

1. Go to Menu > _Account Settings_.
1. _Account Actions_ > _Add Mail Account…_.
1. Insert any valid, but not necessarily existing, email address in the email field.<br/>
   `dummy@example.com` is more than fine.
1. Hit _Configure manually_ as it appears in the wizard.
1. In the _Incoming Server_ configuration, ensure to set it to `POP3` and not `IMAP`.
   You can safely ignore the rest of the server configuration as it is not needed.
1. Hit _Advanced config_ and confirm to create the new dummy account.
1. In the dummy account settings, under _Server Settings_, disable the automatic check for, and download of, new messages on the server.

### Convert an account's message store type from one file per folder (_mbox_) to one file per message (_maildir_)

1. [Create a new dummy account][create a dummy account].
1. Move all the messages to the dummy account.
1. Delete the old account.
1. Recreate the old account.
   > Make sure to select its message store type correctly in the advanced options **before** it starts downloading messages.
1. Move all the messages back.
1. Delete the dummy account.

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
   rm "${THUNDERBIRD_PROFILES_DIR}/we12yhij.default/global-messages-db.sqlite"
   ```

1. Start Thunderbird.

The re-indexing process will start automatically.<br/>
Depending on the number of messages, it might take some time for the indexing to complete; performance might be affected, and the search will return only partial results or even no results until the indexing is complete.

The indexing progress can be monitored through _Tools_ > _Activity Manager_.

### You are already subscribed to this feed

The feed list file is still containing the URL of the feed one is trying to add.

Remove the feed object from the `'Mail/Blog & News Feeds/feeds.json'` file in your profile:

```sh
# Just examples. Check what the command does.
jq 'del(.[1:4])' 'Mail/Blog & News Feeds/feeds.json'
```

## Further readings

- [Betterbird]

## Sources

- [Profile manager - create and remove thunderbird profiles]
- [Profiles - Where Thunderbird stores your messages and other user data]
- [Rebuilding the global database]
- [Arch Wiki]

<!--
  References
  -->

<!-- In-article sections -->
[create a dummy account]: #create-a-dummy-account

<!-- Upstream -->
[profile manager - create and remove thunderbird profiles]: https://support.mozilla.org/en-US/kb/profile-manager-create-and-remove-thunderbird-profiles#
[profiles - where thunderbird stores your messages and other user data]: https://support.mozilla.org/en-US/kb/profiles-where-thunderbird-stores-user-data#
[rebuilding the global database]: https://support.mozilla.org/en-US/kb/rebuilding-global-database#

[importexporttools-ng]: https://addons.thunderbird.net/en-US/thunderbird/addon/importexporttools-ng/
[removedupes]: https://addons.thunderbird.net/en-US/thunderbird/addon/removedupes/

<!-- Others -->
[arch wiki]: https://wiki.archlinux.org/title/thunderbird
[betterbird]: https://www.betterbird.eu/
