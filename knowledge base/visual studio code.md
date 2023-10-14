# Visual Studio Code

## Table of contents <!-- omit in toc -->

1. [Handy keyboard shortcuts](#handy-keyboard-shortcuts)
1. [Handy settings](#handy-settings)
   1. [Built-in](#built-in)
   1. [Extensions settings](#extensions-settings)
1. [Recommend extensions](#recommend-extensions)
   1. [Use JSON schemas](#use-json-schemas)
   1. [Configuration example](#configuration-example)
1. [Network connections](#network-connections)
1. [Troubleshooting](#troubleshooting)
   1. [Blank window upon launch](#blank-window-upon-launch)
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

### Extensions settings

| Extension                  | Setting                                       | Default value | Scopes          | Location in tree                 | Description                                                                                                                                                  |
| -------------------------- | --------------------------------------------- | ------------- | --------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| angelo-breuer.clock        | `clock.alignment`                             | `"Left"`      | User, Workspace | Extensions > Status Bar Clock    | Alignment of the clock on the status bar.                                                                                                                    |
| angelo-breuer.clock        | `clock.format`                                | `"hh:MM"`     | User, Workspace | Extensions > Status Bar Clock    | Date and time format. See https://www.npmjs.com/package/dateformat#mask-options for more options.                                                            |
| ??                         | `git.autofetch`                               | `true`        | User, Workspace | Extensions > Git                 | When set to true, commits will automatically be fetched from the default remote of the current Git repository. Setting to `all` will fetch from all remotes. |
| yzhang.markdown-all-in-one | `markdown.extension.orderedList.autoRenumber` | `true`        | User, Workspace | Extensions > Markdown All In One | Auto fix ordered list markers.                                                                                                                               |
| yzhang.markdown-all-in-one | `markdown.extension.orderedList.marker`       | `"ordered"`   | User, Workspace | Extensions > Markdown All In One | Auto fix ordered list markers.                                                                                                                               |
| yzhang.markdown-all-in-one | `markdown.extension.toc.levels`               | `"1..6"`      | User, Workspace | Extensions > Markdown All In One | Range of levels for the ToC.                                                                                                                                 |
| yzhang.markdown-all-in-one | `markdown.extension.toc.orderedList`          | `false`       | User, Workspace | Extensions > Markdown All In One | Use an ordered list in the ToC.                                                                                                                              |
| redhat.ansible             | `redhat.telemetry.enabled`                    | `true`        | User, Workspace | Extensions > Ansible             | Send telemetry to Red Hat servers.                                                                                                                           |

## Recommend extensions

Add the `extensions.json` file to the workspace's `.vscode` folder with the following structure:

```json
{
  "recommendations": [
    "editorconfig.editorconfig",
    "nhoizey.gremlins",
    "oderwat.indent-rainbow",
    "streetsidesoftware.code-spell-checker",

    "ms-vscode-remote.remote-ssh-edit",
    "redhat.vscode-yaml",
    "yzhang.markdown-all-in-one",

    "casualjim.gotemplate",
    "golang.go",

    "ms-python.python",

    "redhat.ansible",
  ]
}
```

The `recommendations[]` key shall contain the recommended extensions' identifiers from the Visual Studio Marketplace.

### Use JSON schemas

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

### Configuration example

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
  "json.schemas": [
    {
      "fileMatch": ["/.pre-commit-config.yaml"],
      "url": "https://json.schemastore.org/pre-commit-config.json"
    },
  ]
}
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

## Further readings

- [Network connections in Visual Studio Code]

## Sources

- [Using extensions in compiled VSCode]
- [Recommending VSCode extensions within your Open Source projects]
- [VSCode (and some non-patched Electron applications) doesn't run after Tumbleweed update on Nvidia]
- [Electron applications all crash upon launch]

<!--
  References
  -->

<!-- Upstream -->
[network connections in visual studio code]: https://code.visualstudio.com/docs/setup/network
[official product.json]: https://github.com/Microsoft/vscode/blob/master/product.json

<!-- Others -->
[electron applications all crash upon launch]: https://bugs.launchpad.net/ubuntu/+source/glibc/+bug/1944468
[recommending vscode extensions within your open source projects]: https://tattoocoder.com/recommending-vscode-extensions-within-your-open-source-projects/
[using extensions in compiled vscode]: https://stackoverflow.com/questions/44057402/using-extensions-in-compiled-vscode#45291490
[vscode (and some non-patched electron applications) doesn't run after tumbleweed update on nvidia]: https://www.reddit.com/r/openSUSE/comments/ptqlfu/psa_vscode_and_some_nonpatched_electron/
