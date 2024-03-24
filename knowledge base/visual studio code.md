# Visual Studio Code

1. [Configuration](#configuration)
   1. [Handy settings](#handy-settings)
1. [Handy keyboard shortcuts](#handy-keyboard-shortcuts)
1. [Recommend extensions](#recommend-extensions)
1. [Use JSON schemas](#use-json-schemas)
1. [Network connections](#network-connections)
1. [Troubleshooting](#troubleshooting)
   1. [Blank window upon launch](#blank-window-upon-launch)
   1. [_No extensions found_ when running from source](#no-extensions-found-when-running-from-source)
   1. [_Type the name and password of a user in the 'Developer Tools' group to allow Developer Tools Access to make changes_ on Mac OS X](#type-the-name-and-password-of-a-user-in-the-developer-tools-group-to-allow-developer-tools-access-to-make-changes-on-mac-os-x)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Configuration

The configuration consists of the application's defaults, overridden by the user settings first and, if existing, by the workspace settings.<br/>
See the [settings.json] example.

The user configuration is loaded from the `settings.json` file in the user's configuration directory for the application.
The workspace configuration is loaded from the `.vscode/settings.json` file in the workspace's root directory.

### Handy settings

Built-in:

| Setting                                  | Default value | Scopes          | Location in tree            | Description                                                                                                                    |
| ---------------------------------------- | ------------- | --------------- | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `editor.copyWithSyntaxHighlighting`      | `true`        | User, Workspace | Text Editor                 | Copy syntax highlighting too when copying something to the clipboard.                                                          |
| `editor.guides.bracketPairs`             | `false`       | User, Workspace | Text Editor                 | Controls whether bracket pair guides are enabled or not.                                                                       |
| `extensions.autoCheckUpdates`            | `true`        | User            | Features > Extensions       | Automatically check extensions for updates.                                                                                    |
| `extensions.autoUpdates`                 | `true`        | User            | Features > Extensions       | Automatically update extensions.                                                                                               |
| `files.insertFinalNewline`               | `false`       | User, Workspace | Text Editor > Files         | Insert a final newline at the end of the file when saving it.                                                                  |
| `files.trimFinalNewlines`                | `false`       | User, Workspace | Text Editor > Files         | Trim all new lines after the final new line at the end of the file when saving it.                                             |
| `settingsSync.ignoredExtensions`         | `[]`          | User            | Application > Settings Sync | List of extensions to ignore while synchronizing.                                                                              |
| `telemetry.telemetryLevel`               | `"all"`       | User            | Application > Telemetry     | Controls Visual Studio Code telemetry, first-party extension telemetry, and **participating** third-party extension telemetry. |
| `terminal.integrated.cursorBlinking`     | `false`       | User, Workspace | Features > Terminal         | Make the cursor blink in the integrated terminal.                                                                              |
| `terminal.integrated.cursorStyle`        | `"block"`     | User, Workspace | Features > Terminal         | Show the cursor as a block in the integrated terminal.                                                                         |
| `terminal.integrated.defaultProfile.osx` | `null`        | User, Workspace | Features > Terminal         | The default profile used on macOS.                                                                                             |
| `terminal.integrated.scrollback`         | `1000`        | User, Workspace | Features > Terminal         | The maximum number of lines the terminal keeps in its buffer.                                                                  |
| `update.mode`                            | `"default"`   | User            | Application > Update        | Automatically check for application updates.                                                                                   |

Extensions:

| Extension                  | Setting                                       | Default value | Scopes          | Location in tree                 | Description                                                                                                                                                  |
| -------------------------- | --------------------------------------------- | ------------- | --------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| vscode.git (built-in)      | `git.autofetch`                               | `true`        | User, Workspace | Extensions > Git                 | When set to true, commits will automatically be fetched from the default remote of the current Git repository. Setting to `all` will fetch from all remotes. |
| angelo-breuer.clock        | `clock.alignment`                             | `"Left"`      | User, Workspace | Extensions > Status Bar Clock    | Alignment of the clock on the status bar.                                                                                                                    |
| angelo-breuer.clock        | `clock.format`                                | `"hh:MM"`     | User, Workspace | Extensions > Status Bar Clock    | Date and time format. See <https://www.npmjs.com/package/dateformat#mask-options> for more options.                                                          |
| yzhang.markdown-all-in-one | `markdown.extension.orderedList.autoRenumber` | `true`        | User, Workspace | Extensions > Markdown All In One | Auto fix ordered list markers.                                                                                                                               |
| yzhang.markdown-all-in-one | `markdown.extension.orderedList.marker`       | `"ordered"`   | User, Workspace | Extensions > Markdown All In One | Auto fix ordered list markers.                                                                                                                               |
| yzhang.markdown-all-in-one | `markdown.extension.toc.levels`               | `"1..6"`      | User, Workspace | Extensions > Markdown All In One | Range of levels for the ToC.                                                                                                                                 |
| yzhang.markdown-all-in-one | `markdown.extension.toc.orderedList`          | `false`       | User, Workspace | Extensions > Markdown All In One | Use an ordered list in the ToC.                                                                                                                              |
| redhat.ansible             | `redhat.telemetry.enabled`                    | `true`        | User, Workspace | Extensions > Ansible             | Send telemetry to Red Hat servers.                                                                                                                           |

## Handy keyboard shortcuts

| Shortcuts | Effect           |
| --------- | ---------------- |
| `⌘+N`     | New file         |
| `⌥+Z`     | Toggle word wrap |

## Recommend extensions

Add the `extensions.json` file to the workspace's `.vscode` folder.

The `recommendations[]` key shall contain the recommended extensions' identifiers from the Visual Studio Marketplace.<br/>
[Example][extensions.json].

## Use JSON schemas

```json
"json.schemas": [
  {
    "fileMatch": ["/.commitlintrc"],
    "url": "https://json.schemastore.org/commitlintrc.json"
  },
  {
    "fileMatch": ["/.hadolint.yaml"],
    "url": "https://raw.githubusercontent.com/hadolint/hadolint/master/contrib/hadolint.json"
  },
  {
    "fileMatch": ["/.pre-commit-config.yaml"],
    "url": "https://json.schemastore.org/pre-commit-config.json"
  },
  {
    "fileMatch": ["/.yamllint.yaml"],
    "url": "https://json.schemastore.org/yamllint.json"
  }
],
```

## Network connections

See [Network connections in Visual Studio Code].

## Troubleshooting

### Blank window upon launch

[Details and additional links][electron applications all crash upon launch].

It could be caused by a conflict between glibc and Electron's sandboxing or GPU related features.
Run VSCode with one or more of the following flags:

- `--disable-gpu`
- `--disable-gpu-sandbox`

If using MS Teams, also consider using `--no-sandbox`.

### _No extensions found_ when running from source

Check the `extensionsGallery` key in your fork's `product.json` file is using the official marketplace:

```sh
jq '.extensionsGallery' /usr/lib/code/product.json
```

```json
{
  "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
  "cacheUrl": "https://vscode.blob.core.windows.net/gallery/index",
  "itemUrl": "https://marketplace.visualstudio.com/items"
}
```

and if not, change them.

### _Type the name and password of a user in the 'Developer Tools' group to allow Developer Tools Access to make changes_ on Mac OS X

One needs to add one's user name to the `_developer` group:

```sh
sudo dscl . append '/Groups/_developer' GroupMembership "$USER"
```

## Further readings

- [Documentation]
- [Network connections in Visual Studio Code]

## Sources

- [Using extensions in compiled VSCode]
- [Recommending VSCode extensions within your Open Source projects]
- [Official product.json]
- [VSCode (and some non-patched Electron applications) doesn't run after Tumbleweed update on Nvidia]
- [Electron applications all crash upon launch]
- [Authorize a non-admin developer in Xcode / Mac OS]

<!--
  References
  -->

<!-- Files -->
[extensions.json]: ../examples/vscode/extensions.json
[settings.json]: ../examples/vscode/settings.json

<!-- Upstream -->
[documentation]: https://code.visualstudio.com/docs
[network connections in visual studio code]: https://code.visualstudio.com/docs/setup/network
[official product.json]: https://github.com/Microsoft/vscode/blob/master/product.json

<!-- Others -->
[authorize a non-admin developer in xcode / mac os]: https://stackoverflow.com/questions/1837889/authorize-a-non-admin-developer-in-xcode-mac-os#1837935
[electron applications all crash upon launch]: https://bugs.launchpad.net/ubuntu/+source/glibc/+bug/1944468
[recommending vscode extensions within your open source projects]: https://tattoocoder.com/recommending-vscode-extensions-within-your-open-source-projects/
[using extensions in compiled vscode]: https://stackoverflow.com/questions/44057402/using-extensions-in-compiled-vscode#45291490
[vscode (and some non-patched electron applications) doesn't run after tumbleweed update on nvidia]: https://www.reddit.com/r/openSUSE/comments/ptqlfu/psa_vscode_and_some_nonpatched_electron/
