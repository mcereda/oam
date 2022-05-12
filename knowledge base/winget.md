# WinGet

## TL;DR

```powershell
# Search applications.
winget search firefox

# Install applications.
winget install --id Telegram.TelegramDesktop

# List upgradable applications.
winget upgrade

# Upgrade all installed applications.
winget upgrade --all
```

## Installation

> The client requires Windows 10 1809 (build 17763) or later at this time.

### Through the Microsoft Store (recommended)

The client is distributed within the [App Installer package]. While this package is pre-installed on Windows, the client will not be made generally available during the Preview period. In order to get automatic updates from the Microsoft Store that contain the client, one must do one of the following:

- Install a [Windows Insider] build
- [Join the Preview flight ring] by signing up

Note: it may take a few days to get the updated App Installer after you receive e-mail confirmation from joining the Windows Package Manager Insider program. If you decide to install the latest release from GitHub, and you have successfully joined the insider program, you will receive updates when the next stable release has been added to the Microsoft Store.

Once you have received the updated App Installer you should be able to execute `winget`.

### Manual installation

1. install the Windows Desktop App Installer package located on the [Releases page] for the winget [repository]

## Further readings

- Tool [overview]

[overview]: https://docs.microsoft.com/en-us/windows/package-manager/winget/
[releases page]: https://github.com/microsoft/winget-cli/releases
[repository]: https://github.com/microsoft/winget-cli

[app installer package]: https://www.microsoft.com/p/app-installer/9nblggh4nns1
[join the preview flight ring]: http://aka.ms/winget-InsiderProgram
[windows insider]: https://insider.windows.com/
