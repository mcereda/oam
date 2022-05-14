# Keybase

## TL;DR

```sh
# Start the services.
run_keybase
run_keybase -fg

# Authenticate your local service against the keybase server.
keybase login
keybase login --devicename "$(hostname)" --paperkey 'paper key' -s
KEYBASE_DEVICENAME=$(hostname) KEYBASE_PAPERKEY='paper key' keybase login

# Establish a temporary device.
keybase oneshot
keybase oneshot -u user --paperkey 'paper key'
KEYBASE_USERNAME='user' KEYBASE_PAPERKEY='paper key' keybase oneshot

# List git repositories.
keybase git list

# Run garbage collection on git repository.
keybase git gc awesomerepo

# Enable LFS support for a repository.
# Run it from the repository's root.
keybase git lfs-config

# Clone a repository with LFS-enabled files.
git clone --no-checkout keybase://private/user/repo \
  && cd repo && keybase git lfs-config && cd - \
  && git -C repo checkout -f HEAD

# Import an existing repository in Keybase
keybase git create repo \
  && git clone --mirror https://github.com/user/repo /tmp/repo.git \
  && git -C /tmp/repo.git push --mirror keybase://private/user/repo

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

## Import an existing repository in Keybase

Use the import form in [Keybase launches encrypted git], or:

1. Create the remote repository:

   ```sh
   keybase git create dotfiles
   ```

1. Copy the existing repository to a temporary directory:

   ```sh
   git clone --mirror https://github.com/user/dotfiles _tmp.git
   ```

1. Push the contents of the old repository to the new one:

   ```sh
   git -C _tmp.git push --mirror keybase://private/user/dotfiles
   ```

## Run as root

Keybase shouldn't be run as the `root`, and by default it will fail with a message explaining it.  
Under some circumnstances (like Docker or other containers) `root` can be the best or only option; run commands in concert with the `KEYBASE_ALLOW_ROOT=1` environment variable to force the execution.

## Temporary devices

Use `keybase oneshot` to establish a temporary device. The resulting process won't write credential information on the local storage disk nor it will make any changes to the user's sigchain; rather, it will hold the given paperkey in memory for as long as the corrisponding `keybase service` process is running or until `keybase logout` is called; when this happens, it will disappear.

`keybase oneshot` needs a username and a paperkey to work, either passed in via standard input, command-line flags, or environment variables:

```sh
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

## Sources

- [Keybase LFS support]
- [Keybase launches encrypted git]
- [How to use Keybase to encrypt files on Linux]

[how to use keybase to encrypt files on linux]: https://www.addictivetips.com/ubuntu-linux-tips/keybase-encrypt-files-linux/
[keybase launches encrypted git]: https://keybase.io/blog/encrypted-git-for-everyone
[keybase lfs support]: https://github.com/keybase/client/issues/8936
