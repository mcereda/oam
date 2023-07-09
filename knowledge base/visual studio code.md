# Visual Studio Code

## Table of contents <!-- omit in toc -->

1. [Handy keyboard shortcuts](#handy-keyboard-shortcuts)
1. [Handy settings](#handy-settings)
   1. [Built-in](#built-in)
   1. [Extensions](#extensions)
   1. [Example](#example)
1. [Network connections](#network-connections)
1. [Troubleshooting](#troubleshooting)
   1. [_No extensions found_ when running from source](#no-extensions-found-when-running-from-source)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Handy keyboard shortcuts

| Shortcuts | Effect           |
| --------- | ---------------- |
| `⌘+N`     | New file         |
| `⌥+Z`     | Toggle word wrap |

## Handy settings

### Built-in

| Setting                                  | Default value | Scopes          | Location in tree            | Description                                                                                                                    |
| ---------------------------------------- | ------------- | --------------- | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `editor.copyWithSyntaxHighlighting`      | `true`        | User, Workspace | Text Editor                 | Copy syntax highlighting too when copying something to the clipboard.                                                          |
| `extensions.autoCheckUpdates`            | `true`        | User            | Features > Extensions       | Automatically check extensions for updates.                                                                                    |
| `extensions.autoUpdates`                 | `true`        | User            | Features > Extensions       | Automatically update extensions.                                                                                               |
| `files.insertFinalNewline`               | `false`       | User, Workspace | Text Editor > Files         | Insert a final newline at the end of the file when saving it.                                                                  |
| `files.trimFinalNewlines`                | `false`       | User, Workspace | Text Editor > Files         | Trim all new lines after the final new line at the end of the file when saving it.                                             |
| `settingsSync.ignoredExtensions`         | `[]`          | User            | Application > Settings Sync | List of extensions to ignore while synchronizing.                                                                              |
| `telemetry.telemetryLevel`               | `all`         | User            | Application > Telemetry     | Controls Visual Studio Code telemetry, first-party extension telemetry, and **participating** third-party extension telemetry. |
| `terminal.integrated.cursorBlinking`     | `false`       | User, Workspace | Features > Terminal         | Make the cursor blink in the integrated terminal.                                                                              |
| `terminal.integrated.cursorStyle`        | `block`       | User, Workspace | Features > Terminal         | Show the cursor as a block in the integrated terminal.                                                                         |
| `terminal.integrated.defaultProfile.osx` | `null`        | User, Workspace | Features > Terminal         | The default profile used on macOS.                                                                                             |
| `terminal.integrated.scrollback`         | `1000`        | User, Workspace | Features > Terminal         | The maximum number of lines the terminal keeps in its buffer.                                                                  |
| `update.mode`                            | `default`     | User            | Application > Update        | Automatically check for application updates.                                                                                   |

### Extensions

| Extension                  | Setting                                 | Default value | Scopes          | Location in tree                 | Description                                                                                       |
| -------------------------- | --------------------------------------- | ------------- | --------------- | -------------------------------- | ------------------------------------------------------------------------------------------------- |
| angelo-breuer.clock        | `clock.alignment`                       | `Left`        | User, Workspace | Extensions > Status Bar Clock    | Alignment of the clock on the status bar.                                                         |
| angelo-breuer.clock        | `clock.format`                          | `hh:MM`       | User, Workspace | Extensions > Status Bar Clock    | Date and time format. See https://www.npmjs.com/package/dateformat#mask-options for more options. |
| yzhang.markdown-all-in-one | `markdown.extension.orderedList.marker` | `ordered`     | User, Workspace | Extensions > Markdown All In One | Auto fix ordered list markers.                                                                    |
| yzhang.markdown-all-in-one | `markdown.extension.toc.levels`         | `1..6`        | User, Workspace | Extensions > Markdown All In One | Range of levels for the ToC.                                                                      |
| yzhang.markdown-all-in-one | `markdown.extension.toc.orderedList`    | `false`       | User, Workspace | Extensions > Markdown All In One | Use an ordered list in the ToC.                                                                   |
| redhat.ansible             | `redhat.telemetry.enabled`              | `true`        | User, Workspace | Extensions > Ansible             | Send telemetry to Red Hat servers.                                                                |

### Example

```json
{
  "clock.alignment": "Right",
  "clock.format": "yyyy-mm-dd HH:MM",
  "files.trimFinalNewlines": true,
  "markdown.extension.toc.levels": "2..6",
  "redhat.telemetry.enabled": false,
  "settingsSync.ignoredExtensions": [
    "casualjim.gotemplate",
    "golang.go"
  ],
  "telemetry.telemetryLevel": "off",
  "terminal.integrated.cursorBlinking": true,
  "terminal.integrated.cursorStyle": "line",
  "terminal.integrated.defaultProfile.osx": "zsh",
  "terminal.integrated.scrollback": 100000,
  "[markdown]": {
    "editor.defaultFormatter": "yzhang.markdown-all-in-one"
  },
  "editor.copyWithSyntaxHighlighting": false,
  "extensions.autoUpdate": false,
  "files.insertFinalNewline": true,
  "markdown.extension.orderedList.marker": "one",
  "markdown.extension.toc.orderedList": true,
}
```

## Network connections

See [Network connections in Visual Studio Code].

## Troubleshooting

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

## Further readings

- [Network connections in Visual Studio Code]

## Sources

- [Using extensions in compiled VSCode]

<!--
  References
  -->

<!-- Upstream -->
[network connections in visual studio code]: https://code.visualstudio.com/docs/setup/network
[official product.json]: https://github.com/Microsoft/vscode/blob/master/product.json

<!-- Others -->
[using extensions in compiled vscode]: https://stackoverflow.com/questions/44057402/using-extensions-in-compiled-vscode#45291490
