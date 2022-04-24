# Keybase

## TL;DR

```shell
# Start the services.
run_keybase
run_keybase -fg

# Authenticate your local service against the keybase server.
keybase login
KEYBASE_DEVICENAME=$(hostname) keybase login --paperkey "paper key" -s

# Establish a temporary device.
keybase oneshot

# List git repositories.
keybase git list

# Run as root.
KEYBASE_ALLOW_ROOT=1 keybase oneshot
```

## Service execution

`run_keybase` starts the Keybase service, KBFS and the GUI.  
If services are already running, they will be restarted.

Options can also be controlled by setting the related environment variable to 1:

| Option | Description                                         | Environment variable |
| ------ | --------------------------------------------------- | -------------------- |
| `-a`   | keep the GUI minimized in system tray after startup | KEYBASE_AUTOSTART=1  |
| `-f`   | do not start KBFS                                   | KEYBASE_NO_KBFS=1    |
| `-g`   | do not start the gui                                | KEYBASE_NO_GUI=1     |
| `-h`   | print this help text                                | -                    |
| `-k`   | shut down all Keybase services                      | KEYBASE_KILL=1       |

## Run as root

Keybase shouldn't be run as the `root`, and by default it will fail with a message explaining it.  
Under some circumnstances (like Docker or other containers) `root` can be the best or only option; run commands in concert with the `KEYBASE_ALLOW_ROOT=1` environment variable to force the execution.

## Temporary devices

Use `keybase oneshot` to establish a temporary device. The resulting process won't write credential information on the local storage disk nor it will make any changes to the user's sigchain; rather, it will hold the given paperkey in memory for as long as the corrisponding `keybase service` process is running or until `keybase logout` is called; when this happens, it will disappear.

`keybase oneshot` needs a username and a paperkey to work, either passed in via standard input, command-line flags, or environment variables:

```shell
# Provide login information on the standard input.
keybase oneshot

# Use flags.
keybase oneshot --username user --paperkey "paper key"

# Use environment variables
KEYBASE_PAPERKEY="paper key" KEYBASE_USERNAME="user" keybase oneshot
```

Exploding messages work in oneshot mode with the caveat that you cannot run multiple instances of such with the same paperkey at the same time as each instance will try to create ephemeral keys, but require a distinct paperkey to uniquely identify itself as a separate device.  
In addition, ephemeral keys are **purged entirely** when closing the oneshot session, and you will not be able to access any old ephemeral content when starting keybase up again.

## Further readings

- [Website]
- [Linux guide]

[linux guide]: https://book.keybase.io/guides/linux
[website]: https://keybase.io/
