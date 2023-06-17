# SSH

1. [TL;DR](#tldr)
1. [Server installation on Windows](#server-installation-on-windows)
1. [Key Management](#key-management)
1. [Client configuration](#client-configuration)
   1. [Append domains to a hostname before attempting to check if they exist](#append-domains-to-a-hostname-before-attempting-to-check-if-they-exist)
   1. [Optimize connection handling](#optimize-connection-handling)
1. [Server configuration](#server-configuration)
   1. [Change port](#change-port)
   1. [Disable password authentication](#disable-password-authentication)
   1. [Permit root login](#permit-root-login)
   1. [Conditional blocks](#conditional-blocks)
1. [SSHFS](#sshfs)
   1. [Installation](#installation)
1. [Troubleshooting](#troubleshooting)
   1. [No matching host key type found](#no-matching-host-key-type-found)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Create new keys.
ssh-keygen -t 'rsa' -b '4096'
ssh-keygen -t 'dsa'
ssh-keygen -t 'ecdsa' -b '521'
ssh-keygen -t 'ed25519' -f "${HOME}/.ssh/keys/id_ed25519" -C 'test@winzoz'
ssh-keygen -f "${HOME}/.ssh/id_rsa" -N '' -C 'batch-generated key with no password'

# Remove elements from the known hosts list.
ssh-keygen -R 'pi4.lan'
ssh-keygen -R '192.168.1.237' -f '.ssh/known_hosts'
ssh-keygen -R 'pi.lan' -f "${HOME}/.ssh/known_hosts"

# Change the password of a key.
ssh-keygen -f "${HOME}/.ssh/id_rsa" -p

# Show keys' fingerprint.
ssh-keygen -l -f "${HOME}/.ssh/id_ed25519"

# Show certificates' content.
ssh-keygen -L -f 'path/to/ssh.cert'

# Load keys from '${HOME}/.ssh' and add them to the agent.
eval $(ssh-agent) && ssh-add

# List keys added to the agent, by fingerprint.
ssh-add -l

# List keys added to the agent, by public key.
ssh-add -L

# Authorize keys for passwordless access.
ssh-copy-id 'host.fqdn'
ssh-copy-id -i "${HOME}/.ssh/id_rsa.pub" 'user@host.fqdn'

# Preload trusted keys.
ssh-keyscan 'host.fqdn' >> "${HOME}/.ssh/known_hosts"

# Connect to an unreachable host tunnelling the session through a bastion.
ssh -t 'bastion-host' ssh 'unreachable-host'

# Mount a remote folder.
sshfs 'nas.lan:/mnt/data' 'Data' \
  -o 'auto_cache,reconnect,defer_permissions,noappledouble,volname=Data'
```

## Server installation on Windows

Needs Administrator privileges.<br/>
Tested on Window 11 22H2.

Via PowerShell:

1. Install the server component:

   ```ps1
   Add-WindowsCapability -Online -Name OpenSSH.Server
   ```

1. Start and enable the service:

   ```ps1
   Start-Service sshd
   Set-Service -Name sshd -StartupType 'Automatic'
   ```

1. Verify the firewall rule has been created automatically during the installation:

   ```ps1
   if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
     Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
     New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
   } else {
     Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
   }
   ```

Via GUI:

1. Open _Settings_ > _Apps_, then select _Optional features_
1. Scan the list to see if the OpenSSH server is not already installed
1. At the top of the page, select _View features_ in the _Add an optional feature_ field
1. Find _OpenSSH Server_ and select _Install_
1. Once the setup completes, return to _Apps_ > _Optional features_ and confirm OpenSSH is now listed
1. Open the _Services_ desktop app:

   1. Select Start
   1. Type `services.msc` in the search box
   1. Select the _Services_ app or just press ENTER

1. In the details panel, double-click _OpenSSH SSH Server_ to enter its properties
1. On the _General_ tab, from the _Startup type_ drop-down menu, select _Automatic_ to enable the service
1. In the same tab, select _Start_ to start the service

## Key Management

Create a new key:

```sh
ssh-keygen -t 'rsa' -b '4096'
ssh-keygen -t 'dsa'
ssh-keygen -t 'ecdsa' -b '521'
ssh-keygen -t 'ed25519' -f '.ssh/id_ed25519' -C 'test@winzoz'
```

```txt
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
ssh-keygen -R 'pi4.lan'
ssh-keygen -R '192.168.1.237' -f '.ssh/known_hosts'
ssh-keygen -R 'raspberrypi.lan' -f '.ssh/known_hosts'
```

```txt
Host pi4.lan found: line 5
/home/user/.ssh/known_hosts updated.
Original contents retained as /home/user/.ssh/known_hosts.old
```

Change password of a key file

```sh
ssh-keygen -f "${HOME}/.ssh/id_rsa" -p
```

## Client configuration

When connecting to a host, the SSH client will use settings:

1. from the command line,
1. from the user's `~/.ssh/config` file,
1. from the `/etc/ssh/ssh_config` file

Settings are loaded in a first-come-first-served way. They should hence appear from the most specific to the most generic, both by file and by position in those files:

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
    sendenv BE_SASSY
    StrictHostKeyChecking no

Host * !martell
    LogLevel INFO
    StrictHostKeyChecking accept-new
    UserKnownHostsFile /dev/null

Host *
    User root
    Compression yes
    SendEnv -LC_* -LANG*
    SetEnv MYENV=itsvalue
```

### Append domains to a hostname before attempting to check if they exist

```ssh-config
CanonicalizeHostname yes
CanonicalDomains xxx.auckland.ac.nz yyy.auckland.ac.nz

Host  *.xxx.auckland.ac.nz
    User user_xxx
Host  *.yyy.auckland.ac.nz
    User user_yyy
```

### Optimize connection handling

```ssh-config
# Keep a connection open for 30s and reuse it when possible.
# Save the above pipe in a safe directory, and use a hash of different data to
# identify it.
# source: https://www.cyberciti.biz/faq/linux-unix-reuse-openssh-connection/
ControlMaster auto
ControlPath ~/.ssh/control-%C
ControlPersist 30s
```

## Server configuration

Config file defaults to `/etc/ssh/sshd_config`.<br/>
Restart the server upon config file change.

### Change port

```ssh-config
Port 2222
```

### Disable password authentication

```ssh-config
PasswordAuthentication no
ChallengeResponseAuthentication no
```

### Permit root login

```ssh-config
PermitRootLogin yes
```

### Conditional blocks

> Only a subset of keywords may be used in a _Match_ block. Check the [`SSHD_CONFIG(5)`][sshd_config man page] man page.

```ssh-config
Match Address 192.168.111.0/24
    PasswordAuthentication no
    PermitRootLogin no
```

## SSHFS

Notable options:

- `auto_cache` enables caching based on modification times;
- `reconnect` reconnects to the server;
- `defer_permissions` works around the issue where certain shares may mount properly, but cause _permissions denied_ errors when accessed (caused by how Mac OS X's Finder translates and interprets permissions;
- `noappledouble` prevents Mac OS X to write `.DS_Store` files on the remote file system;
- `volname` defines the name to use for the volume.

Usage:

```sh
sshfs \
  -o 'auto_cache,reconnect,defer_permissions,noappledouble,volname=Data'
  'user@nas.lan:/path/to/remote/dir' \
  '/path/to/local/dir'
```

### Installation

```sh
# Mac OS X requires `macports`, since `brew` does not offer 'sshfs' anymore
sudo port install 'sshfs'
```

## Troubleshooting

### No matching host key type found

Error message example:

> `Unable to negotiate with XXX port 22: no matching host key type found. Their offer: ssh-rsa.`

Cause: the server only supports the kind of RSA with SHA-1, which is considered weak and deprecated in newer SSH versions.

Workaround: explicitly set your client to use the specified key type adding

```ssh-config
HostkeyAlgorithms        +ssh-rsa
PubkeyAcceptedAlgorithms +ssh-rsa
```

to your `~/.ssh/config` like so:

```diff
Host  azure-devops
    IdentityFile              ~/.ssh/id_rsa
    IdentitiesOnly            yes
+   HostkeyAlgorithms         +ssh-rsa
+   PubkeyAcceptedAlgorithms  +ssh-rsa
```

Solution: update the SSH server.

## Further readings

- [`SSH_CONFIG(5)`][ssh_config man page] man page
- [`ssh_config`][ssh_config example] example
- [`SSHD_CONFIG(5)`][sshd_config man page] man page
- [`sshd_config`][sshd_config example] example
- [ssh-agent]

## Sources

- [Use SSHFS to mount a remote directory as a volume on OSX]
- [Using the SSH config file]
- [How to list keys added to ssh-agent with ssh-add?]
- [Multiple similar entries in ssh config]
- [How to enable SSH access using a GPG key for authentication]
- [How to perform hostname canonicalization]
- [How to reuse SSH connection to speed up remote login process using multiplexing]
- [Get started with OpenSSH for Windows]
- [Restrict SSH login to a specific IP or host]

<!-- project's references -->
[ssh_config man page]: https://man.openbsd.org/ssh_config
[ssh-agent]: https://www.ssh.com/academy/ssh/agent
[sshd_config man page]: https://man.openbsd.org/sshd_config

<!-- internal references -->
[ssh_config example]: ../examples/ssh/ssh_config
[sshd_config example]: ../examples/ssh/sshd_config

<!-- external references -->
[get started with openssh for windows]: https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=gui
[how to enable ssh access using a gpg key for authentication]: https://opensource.com/article/19/4/gpg-subkeys-ssh
[how to list keys added to ssh-agent with ssh-add?]: https://unix.stackexchange.com/questions/58969/how-to-list-keys-added-to-ssh-agent-with-ssh-add
[how to perform hostname canonicalization]: https://sleeplessbeastie.eu/2020/08/24/how-to-perform-hostname-canonicalization/
[how to reuse ssh connection to speed up remote login process using multiplexing]: https://www.cyberciti.biz/faq/linux-unix-reuse-openssh-connection/
[multiple similar entries in ssh config]: https://unix.stackexchange.com/questions/61655/multiple-similar-entries-in-ssh-config
[restrict ssh login to a specific ip or host]: https://docs.rackspace.com/support/how-to/restrict-ssh-login-to-a-specific-ip-or-host/
[use sshfs to mount a remote directory as a volume on osx]: https://benohead.com/mac-os-x-use-sshfs-to-mount-a-remote-directory-as-a-volume/
[using the ssh config file]: https://linuxize.com/post/using-the-ssh-config-file/
