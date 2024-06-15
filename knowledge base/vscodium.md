# VSCodium

## Troubleshooting

### Zsh terminal icons are not getting displayed in the terminal

Change font to `NotoSansMono Nerd Font` in the _Terminal_ > _Integrated_ > _Font Family_ settings.  
See [Why Zsh terminal icons are not getting displayed in Atom Platformio Ide Terminal?]

## Flatpak version

In case you missed, the README file is at `/app/share/codium/README.md`

### FAQ

This version is running inside a _container_ and is therefore __not able__
to access SDKs on your host system!

#### To execute commands on the host system, run inside the sandbox

```bash
flatpak-spawn --host <COMMAND>
```

#### Host Shell

To make the Integrated Terminal automatically use the host system's shell,
you can add this to the settings of vscodium:

```json
{
  "terminal.integrated.shell.linux": "/usr/bin/env",
  "terminal.integrated.shellArgs.linux": ["--", "flatpak-spawn", "--host", "bash"]
}
```

#### SDKs

This flatpak provides a standard development environment (gcc, python, etc).
To see what's available:

```bash
flatpak run --command=sh com.vscodium.codium
ls /usr/bin (shared runtime)
ls /app/bin (bundled with this flatpak)
```

To get support for additional languages, you have to install SDK extensions, e.g.

```bash
flatpak install flathub org.freedesktop.Sdk.Extension.dotnet
flatpak install flathub org.freedesktop.Sdk.Extension.golang
FLATPAK_ENABLE_SDK_EXT=dotnet,golang flatpak run com.vscodium.codium
```

You can use

```bash
flatpak search <TEXT>
```

to find others.

#### Run flatpak codium from host terminal

If you want to run `codium /path/to/file` from the host terminal just add this to your shell's rc file

```bash
alias codium="flatpak run com.vscodium.codium"
```

then reload sources, now you could try:

```bash
$ codium /path/to/
# or
$ FLATPAK_ENABLE_SDK_EXT=dotnet,golang codium /path/to/
```

## Sources

- [Why Zsh terminal icons are not getting displayed in Atom Platformio Ide Terminal?]

[why zsh terminal icons are not getting displayed in atom platformio ide terminal?]: https://forum.manjaro.org/t/why-zsh-terminal-icons-are-not-getting-displayed-in-atom-platformio-ide-terminal/64885/2
