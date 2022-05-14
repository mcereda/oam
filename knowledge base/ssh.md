# SSH

## TL;DR

```sh
# load ssh keys from ~/.ssh and add them to the agent
eval `ssh-agent` && ssh-add

# create a new ssh key
ssh-keygen -t rsa -b 4096
ssh-keygen -t dsa
ssh-keygen -t ecdsa -b 521
ssh-keygen -t ed25519 -f ~/.ssh/keys/id_ed25519 -C test@winzoz

# remove an element from the list of known hosts
ssh-keygen -R "pi4.lan"
ssh-keygen -R 192.168.1.237 -f .ssh/known_hosts
ssh-keygen -R "raspberrypi.lan" -f "${HOME}/.ssh/known_hosts"

# change the password of a key file
ssh-keygen -f ~/.ssh/id_rsa -p

# mount a remote folder
sshfs nas.lan:/mnt/data Data -o auto_cache,reconnect,defer_permissions,noappledouble,volname=Data

# list keys added to the agent by fingerprint
ssh-add -l
ssh-add -L   # full key in OpenSSH format

# authorize a key for passwordless access
ssh-copy-id -i ~/.ssh/id_rsa.pub user@nas.lan
```

## Key Management

Create a new key:

```sh
ssh-keygen -t rsa -b 4096
ssh-keygen -t dsa
ssh-keygen -t ecdsa -b 521
ssh-keygen -t ed25519 -f .ssh/id_ed25519 -C test@winzoz
```

```plaintext
Generating public/private ed25519 key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in C:\Users\test/.ssh/id_ed25519.
Your public key has been saved in C:\Users\test/.ssh/id_ed25519.pub.
The key fingerprint is:
SHA256:lFrpPyqTy0d30TfnN0QRY678LnyCzmvMDbl1Qj2/U/w test@winzoz
The key's randomart image is:
+--[ED25519 256]--+
|           +o.o++|
|             ==*O|
|            . .X*|
|         o .   +=|
|        S S +..==|
|         . .+..*E|
|           + ...o|
|         .+ .o = |
|          =+ .o .|
+----[SHA256]-----+
```

Remove a host from the list of known hosts:

```sh
ssh-keygen -R "pi4.lan"
ssh-keygen -R 192.168.1.237 -f .ssh/known_hosts
ssh-keygen -R "raspberrypi.lan" -f ".ssh/known_hosts"
```

```plaintext
Host pi4.lan found: line 5
/home/mek/.ssh/known_hosts updated.
Original contents retained as /home/mek/.ssh/known_hosts.old
```

Change password of a key file

```sh
ssh-keygen -f ~/.ssh/id_rsa -p
```

## SSHFS

Options:

- `auto_cache` enables caching based on modification times
- `reconnect` reconnects to server
- `defer_permissions` certain shares may mount properly but cause permissions denied errors when accessed (an issue caused by the way permissions are translated and interpreted by the Mac OS X Finder). This option works around this problem
- `noappledouble` prevents Mac OS X to write `.DS_Store` files on the remote file system
- `volname` the volume name to be used

Usage:

```sh
sshfs -o $OPTIONS_LIST $HOST:$REMOTE_PATH $LOCAL_PATH
```

Example:

```sh
sshfs user@nas.lan:/mnt/data Data -o auto_cache,reconnect,defer_permissions,noappledouble,volname=Data
```

### Installation

OSX (requires macports since brew does not offer sshfs anymore):

```sh
sudo port install sshfs
```

## Configuration

When connecting to a host, the SSH client will use settings:

1. from the command line
1. from the user's `~/.ssh/config` file
1. from the `/etc/ssh/ssh_config` file

```ssh-config
Host targaryen
    HostName targaryen.example.com
    User john
    Port 2322
    IdentityFile ~/.ssh/targaryen.key
    LogLevel INFO
    Compression yes

Host *ell
    user oberyn

Host * !martell
    LogLevel INFO

Host *
    User root
    Compression yes
```

```ssh-config
# append domains to a hostname before attempting to check if they exist
CanonicalizeHostname yes
CanonicalDomains xxx.auckland.ac.nz yyy.auckland.ac.nz

Host  *.xxx.auckland.ac.nz
    User myuser
Host *.yyy.auckland.ac.nz
    User myotheruser
```

```ssh-config
# keep a connection open for 30s to be reused
# save the pipe in a safe directory
# use a hash of different data for pipe identification
# source: https://www.cyberciti.biz/faq/linux-unix-reuse-openssh-connection/
ControlMaster auto
ControlPath ~/.ssh/control-%C
ControlPersist 30s
```

## Further readings

- [ssh-agent]

## Sources

- [Use SSHFS to mount a remote directory as a volume on OSX]
- [Using the SSH config file]
- [How to list keys added to ssh-agent with ssh-add?]
- [Multiple similar entries in ssh config]
- [How to enable SSH access using a GPG key for authentication]
- [How to perform hostname canonicalization]
- [How to reuse SSH connection to speed up remote login process using multiplexing]

[ssh-agent]: https://www.ssh.com/academy/ssh/agent

[how to enable ssh access using a gpg key for authentication]: https://opensource.com/article/19/4/gpg-subkeys-ssh
[how to list keys added to ssh-agent with ssh-add?]: https://unix.stackexchange.com/questions/58969/how-to-list-keys-added-to-ssh-agent-with-ssh-add
[how to perform hostname canonicalization]: https://sleeplessbeastie.eu/2020/08/24/how-to-perform-hostname-canonicalization/
[how to reuse ssh connection to speed up remote login process using multiplexing]: https://www.cyberciti.biz/faq/linux-unix-reuse-openssh-connection/
[multiple similar entries in ssh config]: https://unix.stackexchange.com/questions/61655/multiple-similar-entries-in-ssh-config
[use sshfs to mount a remote directory as a volume on osx]: https://benohead.com/mac-os-x-use-sshfs-to-mount-a-remote-directory-as-a-volume/
[using the ssh config file]: https://linuxize.com/post/using-the-ssh-config-file/
