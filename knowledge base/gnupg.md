# GnuPG

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
2. [Create new keys](#create-new-keys)
   1. [Create new keys non-interactively](#create-new-keys-non-interactively)
   2. [Create keys or subkeys capable of authenticating](#create-keys-or-subkeys-capable-of-authenticating)
3. [Trust keys](#trust-keys)
4. [Change keys' passwords](#change-keys-passwords)
5. [Export keys](#export-keys)
6. [Import keys](#import-keys)
7. [Encrypt files](#encrypt-files)
8. [Decrypt files](#decrypt-files)
9. [Put comments in a message or file](#put-comments-in-a-message-or-file)
10. [Use GPG keys for SSH authentication](#use-gpg-keys-for-ssh-authentication)
    1. [Allow the SSH agent to use GPG (sub)keys](#allow-the-ssh-agent-to-use-gpg-subkeys)
    2. [Share GPG-SSH keys](#share-gpg-ssh-keys)
11. [Troubleshooting](#troubleshooting)
    1. [`gpg failed to sign the data; fatal: failed to write commit object`](#gpg-failed-to-sign-the-data-fatal-failed-to-write-commit-object)
    2. [`sign_and_send_pubkey: signing failed for … from agent: agent refused operation`](#sign_and_send_pubkey-signing-failed-for--from-agent-agent-refused-operation)
    3. [New configuration settings are ineffective](#new-configuration-settings-are-ineffective)
12. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

Keygrips are internal identifiers that `gpg-agent` uses to refer to them.\
One keygrip references both the public and private key.

<details>
  <summary>Setup</summary>

```sh
# Install on Linux.
apt install 'gnupg'

# Install on macOS.
# Choose one.
brew install --cask 'gpg-suite-no-mail'
brew install 'gnupg' 'pinentry-mac'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Launch components.
gpgconf --launch
gpgconf --launch 'gpg-agent'

# Reload components.
gpgconf -R
gpgconf --reload 'gpg-agent'

# Kill components.
gpgconf -K 'all'
gpgconf --kill 'gpg-agent'

# Update the agent's knowledge of the current terminal.
# Needed after switching terminals or when Pinentry can't find the TTY.
gpg-connect-agent updatestartuptty /bye
gpg-connect-agent reloadagent '/bye'


# List existing keys.
gpg -k
gpg --list-keys --keyid-format 'short'
gpg -K --with-subkey-fingerprint
gpg --list-secret-keys --with-keygrip --keyid-format '0xlong'

# Generate new keys.
gpg --gen-key
gpg --generate-key
gpg --full-generate-key
gpg --expert --full-generate-key

# Generate new key in an unattended way.
# The non-interactive (--batch) option requires a settings file.
gpg --generate-key --batch 'setting.txt'
gpg --generate-key --batch <<-EOF
…
EOF

# Import keys from files.
gpg --import 'keys.asc'

# Export keys to files.
gpg -a --export > 'all.public-keys.asc'
gpg --armor --export -o 'given.public-key.asc' 'key_fingerprint'
gpg -a --export-secret-keys --output 'all.private-keys.asc'
gpg -a --export-secret-subkeys 'subkey_fingerprint'! > 'given.private-subkey.asc'

# Delete keys from the keyring.
# The non-interactive (--batch) option requires the key fingerprint.
gpg --delete-secret-key 'recipient'
gpg --delete-key 'recipient'
gpg --delete-keys --batch 'key_fingerprint'

# Get keys' fingerprint information.
gpg --fingerprint
gpg --fingerprint 'recipient'

# Change keys' expiration date.
# Use '0', 'never' or 'none' as expiration period to disable expiration.
# Use '*' as subkey fingerprint to set the expiration date of all non-revoked
# subkeys.
gpg --quick-set-expire 'key_fingerprint' '0'
gpg --quick-set-expire 'key_fingerprint' '2085-11-24'
gpg --quick-set-expire 'key_fingerprint' '20241101T203012' 'subkey_fingerprint'
gpg --quick-set-expire 'key_fingerprint' '1y' '*'

# Generate revocation certificates.
# To actually revoke the key, merge it with the certificate using '--import'.
# Use the '--edit' command to only revoke a subkey or a key signature.
gpg --gen-revoke
gpg --generate-revocation -ao 'revoke.cert' 'fingerprint'

# Save auto-generated revocation certificates.
# GnuPG auto-generates revocation certificates in 'openpgp-revocs.d/'.
cp "$HOME/.gnupg/openpgp-revocs.d/key_fingerprint.rev" 'revocation-cert.rev'

# Change keys' passphrase.
# Use '--dry-run' to just check the current password is correct.
gpg --passwd 'fingerprint'
gpg --change-passphrase --dry-run 'recipient'


# Encrypt files *a*symmetrically.
gpg -o 'file.out.gpg' -r 'recipient' -e 'file.in'
gpg -o 'file.out.gpg' -u 'sender' -r 'recipient' --encrypt 'file.in'
gpg --encrypt-files --batch -r 'recipient' 'file.in.1' 'file.in.N'
gpg -e --multifile --batch -r 'recipient' --yes 'file.in.1' 'file.in.N'

# Encrypt files *symmetrically*.
# Simply encrypts data with a passphrase.
gpg -c 'input.file'
gpg --symmetric --s2k-cipher-algo 'AES256' --s2k-digest-algo 'SHA512' \
  --s2k-count '65536' 'input.file'

# Encrypt files for multiple recipients.
gpg -e … -r 'recipient_1' -r 'key_fingerprint' -r 'recipient_N'

# Decrypt files.
gpg -d 'file.gpg'
gpg -o 'file.out' --decrypt 'file.in.gpg'
gpg --decrypt-files --batch 'file.in.gpg.1' 'file.in.gpg.N'
gpg -d --multifile --batch --yes 'file.in.gpg.1' 'file.in.gpg.N'

# Encrypt directories.
gpgtar -o 'dir.tar.gpg' -c 'input/dir'

# Decrypt directories.
gpgtar -d 'dir.tar.gpg'
gpgtar -o 'dir' -d 'dir.tar.gpg'


# Sign data.
gpg --detach-sign 'file'
gpg -a --default-key 'key_identifier' --detach-sign 'file'
echo 'token' | gpg -a --default-key 'key_identifier' --detach-sign


# Get the short ID of a key for a user.
# The simple version works when the user has a single key.
# The second filters for keys with the [S]igning capability, for when one has multiple keys with different capabilities.
# Primarily usable for git's signingKey configuration.
gpg --list-keys --keyid-format 'short' 'recipient' \
| grep --extended-regexp '^pub' \
| awk -F '/' '{print $2}' | awk '{print $1}'
gpg --list-keys --keyid-format 'short' 'recipient' \
| grep --extended-regexp '^pub[[:blank:]]+[[:alnum:]]+/[[:alnum:]]+[[:blank:]].*\[[[:upper:]]*S[[:upper:]]*\]' \
| awk '{print $2}' \
| cut -d '/' -f 2


# Integrate with the SSH agent.
export SSH_AUTH_SOCK="$(gpgconf --list-dirs 'agent-ssh-socket')" && \
gpgconf --launch 'gpg-agent'

# Export keys in OpenSSH format.
gpg --export-ssh-key 'key_identifier'
gpg --export-ssh-key 'ed25519_key' > ~'/.ssh/id_ed25519.pub'


# Integrate with Pinentry.
export GPG_TTY="$(tty)"


# Only get the base64 armored string in the key
# -e '/^-----/d' removes the header and footer
# -e '/^=/d' removes the base64 checksum at the bottom
# -e '/^$/d' removes empty lines
gpg --armor --export 'someone@example.org' | sed -e '/^-----/d' -e '/^=/d' -e '/^$/d'
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Sign a token to prove ownership of a GPG key.
# Used by services like Gitea to verify key association.
echo '1d64…9920' | gpg -a --default-key 'E455…50AB' --detach-sign

# Decrypt an encrypted key backup and import it.
gpg --decrypt --output - 'keys.asc.gpg' | gpg --import

# Encrypt specific files found by pattern.
find . -type 'f' -name 'secret.txt' \
  -exec gpg --batch --yes --encrypt-files --recipient 'recipient' {} ';'

# List SSH keys.
gpg-connect-agent 'keyinfo --ssh-list' '/bye' 2>'/dev/null'
```

</details>

## Create new keys

```sh
gpg --gen-key
gpg --generate-key
gpg --full-generate-key
gpg --expert --full-generate-key
```

### Create new keys non-interactively

> [!important]
> The non-interactive (`--batch`) option **requires** the user to specify a settings file.

```sh
# basic key with default values
gpg --batch --generate-key <<EOF
    %echo Generating a default key
    Key-Type: default
    Subkey-Type: default
    Name-Real: Joe Tester
    Name-Comment: with stupid passphrase
    Name-Email: joe@foo.bar
    Expire-Date: 0
    Passphrase: abc
    # Do a commit here, so that we can later print "done" :-)
    %commit
    %echo done
EOF
```

### Create keys or subkeys capable of authenticating

One can enable the authentication capability on a **new** key while creating it.

Creating **subkeys** requires one to already have a GPG key to subordinate it to.\
To create a new subkey, edit an existing key **in expert mode** to get access to the appropriate options:

```sh
$ gpg --expert --edit-key 'key_fingerprint'
gpg> addkey
Please select what kind of key you want:
   (3) DSA (sign only)
   (4) RSA (sign only)
   (5) Elgamal (encrypt only)
   (6) RSA (encrypt only)
   (7) DSA (set your own capabilities)
   (8) RSA (set your own capabilities)
  (10) ECC (sign only)
  (11) ECC (set your own capabilities)
  (12) ECC (encrypt only)
  (13) Existing key
Your selection? 8

Possible actions for a RSA key: Sign Encrypt Authenticate
Current allowed actions: Sign Encrypt

   (S) Toggle the sign capability
   (E) Toggle the encrypt capability
   (A) Toggle the authenticate capability
   (Q) Finished

Your selection? s
Your selection? e
Your selection? a

Possible actions for a RSA key: Sign Encrypt Authenticate
Current allowed actions: Authenticate

   (S) Toggle the sign capability
   (E) Toggle the encrypt capability
   (A) Toggle the authenticate capability
   (Q) Finished

Your selection? q
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (4096)
Requested keysize is 4096 bits
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0)
Key does not expire at all
Is this correct? (y/N) y
Really create? (y/N) y

sec  rsa2048/8715AF32191DB135
     created: 2019-03-21  expires: 2021-03-20  usage: SC
     trust: ultimate      validity: ultimate
ssb  rsa2048/150F16909B9AA603
     created: 2019-03-21  expires: 2021-03-20  usage: E
ssb  rsa4096/17E7403F18CB1123
     created: 2019-03-21  expires: never       usage: A
[ultimate] (1). Johnny B. Good

gpg> quit
Save changes? (y/N) y
```

## Trust keys

```sh
$ gpg --edit-key 'key_fingerprint'
gpg> trust
gpg> quit
```

## Change keys' passwords

```sh
$ gpg --edit-key 'key_fingerprint'
gpg> passwd
gpg> quit
```

## Export keys

As the original user, export all public keys to a base64-encoded text file and create an encrypted version of that file:

```sh
# Export.
gpg --armor --export > 'all.public-keys.asc'
gpg --armor --export 'recipient' > 'recipient.public-keys.asc'

# Encryption.
gpg --output 'file.out.gpg' --encrypt --recipient 'recipient' 'file.in'
gpg --armor --symmetric --output 'file.out.gpg' 'file.in'
```

Export all encrypted private keys (which will also include corresponding public keys) to a text file and create an
encrypted version of that file:

```sh
# Export.
gpg --armor --export-secret-keys > 'all.private-keys.asc'
gpg --armor --export-secret-keys 'recipient' > 'recipient.private-keys.asc'

# Encryption.
gpg --output 'file.out.gpg' --encrypt --recipient 'recipient' 'file.in'
gpg --armor --symmetric --output 'file.out.gpg' 'file.in'
```

Optionally, also export `gpg`'s trustdb to a text file:

```sh
gpg --export-ownertrust > 'otrust.txt'
```

## Import keys

As the new user execute `gpg --import` commands against the secured files, or the decrypted content of those files, and
then check for the new keys with `gpg -k` and `gpg -K`, e.g.:

```sh
gpg --output 'myprivatekeys.asc' --decrypt 'mysecretatedprivatekeys.sec.asc' && \
gpg --import 'myprivatekeys.asc'
gpg --output 'mypubkeys.asc' --decrypt 'mysecretatedpubkeys.sec.asc'
gpg --import 'mypubkeys.asc'
gpg --list-secret-keys
gpg --list-keys
```

Optionally import the trustdb file as well:

```sh
gpg --import-ownertrust 'otrust.txt'
```

## Encrypt files

```sh
# Single file.
gpg --output 'file.out.gpg' --encrypt --recipient 'recipient' 'file.in'
gpg --armor --symmetric --output 'file.out.gpg' 'file.in'

# All files found.
find . -type 'f' -name 'secret.txt' \
  -exec gpg --batch --yes --encrypt-files --recipient 'recipient' {} ';'
```

## Decrypt files

```sh
# Single file.
gpg -d 'file.gpg'
gpg --output 'file.out' --decrypt 'file.in.gpg'

# All files found.
find . -type f -name "*.gpg" -exec gpg --decrypt-files {} +
```

The second command will create the decrypted version of all files in the same directory. Each file will have the same
name of the encrypted version, minus the `.gpg` extension.

## Put comments in a message or file

One can put comments in an armored ASCII message or key block using the `Comment` keyword for each line:

```txt
-----BEGIN PGP MESSAGE-----
Comment: …
Comment: …

hQIMAwbYc…
-----END PGP MESSAGE-----
```

OpenPGP defines all text to be in UTF-8, so a comment may be any UTF-8 string.\
The whole point of armoring, however, is to provide seven-bit-clean data, so if a comment has characters that are
outside the US-ASCII range of UTF they may very well not survive transport.

## Use GPG keys for SSH authentication

See also [How to enable SSH access using a GPG key for authentication].

This exercise will use a dedicated GPG subkey that only has the authentication capability enabled.\
One can create multiple subkeys the same way they would do for SSH key pairs.

1. Make sure at least one key or subkey capable of authenticating is available:

   ```sh
   $ gpg -K
   /home/jbgood/.gnupg/pubring.kbx
   -----------------------------
   sec   rsa4096 2017-11-13 [SC] [expires: 2025-11-12]
         7425E11D898C449FDD3D1B4A7E747A8618CB109F
   uid           [ultimate] Johnny B. Good <j.b.good@email.com>
   uid           [ultimate] Johnny <johnny@mymail.com>
   ssb   rsa4096 2018-01-03 [E]
   ssb   rsa4096 2018-05-04 [A]

   sec   rsa4096 2022-01-03 [SCEA] [expires: 2025-01-02]
         8B6DC0BF4D73373C2A529C65CC54F9AC6E542DE7
   uid           [ unknown] Luna Varasi <luna.var@example.com>
   ```

   If none is, [create one][create keys or subkeys capable of authenticating].

1. Make sure the desired (sub)keys are [trusted][trust keys].
1. [Allow the SSH agent to use GPG (sub)keys].

### Allow the SSH agent to use GPG (sub)keys

`ssh-agent` manages SSH keys. `gpg-agent` manages GPG keys.\
Enable the GPG agent's SSH support to allow it to handle requests from the SSH agent:

```sh
echo 'enable-ssh-support' >> ~'/.gnupg/gpg-agent.conf'
```

> [!tip]
> Avoid the need of using `ssh-add` to load the keys every time by preemptively by specifying each allowed GPG key's
> _keygrip_ in the `~/.gnupg/sshcontrol` file.
>
> <details>
>
> 1. Find the keygrips to allow:
>
>    ```sh
>    $ gpg -K --with-keygrip
>    /home/jbgood/.gnupg/pubring.kbx
>    -----------------------------
>    sec   rsa4096 2017-11-13 [SC] [expires: 2025-11-12]
>          7425E11D898C449FDD3D1B4A7E747A8618CB109F
>          Keygrip = E045864F555B3432E6DFCA2EF7ED47403A6E399C
>    uid           [ultimate] Johnny B. Good <j.b.good@email.com>
>    uid           [ultimate] Johnny <johnny@mymail.com>
>    ssb   rsa4096 2018-01-03 [E]
>          Keygrip = B4674D4429AE049663BE4FEF9407C6B90F7AF122
>    ssb   rsa4096 2018-05-04 [A]
>          Keygrip = B3D630644D14A452502A84FB09E5257CF54C3E04
>
>    sec   rsa4096 2022-01-03 [SCEA] [expires: 2025-01-02]
>          8B6DC0BF4D73373C2A529C65CC54F9AC6E542DE7
>          Keygrip = 03CE1FCE255AC0BB747BBBF61C9B8378CF78A2FC
>    uid           [ unknown] Luna Varasi <luna.var@example.com>
>    ```
>
> 1. Add them to the `~/.gnupg/sshcontrol` file:
>
>    ```sh
>    echo 'B3D630644D14A452502A84FB09E5257CF54C3E04' >> ~'/.gnupg/sshcontrol'
>    echo '03CE1FCE255AC0BB747BBBF61C9B8378CF78A2FC' >> ~'/.gnupg/sshcontrol'
>    ```
>
> 1. Tell SSH how to access the GPG agent by setting the value of the `SSH_AUTH_SOCK` environment variable.
>
>    ```sh
>    export SSH_AUTH_SOCK=$(gpgconf --list-dirs 'agent-ssh-socket')
>    ```
>
>    Alternatively, and for a more permanent solution, set the option in one's `.ssh/config` file:
>
>    ```sh
>    echo "\nIdentityAgent $(gpgconf --list-dirs 'agent-ssh-socket')" \
>    | tee -a ~'/.ssh/config'
>    ```
>
> 1. Launch the gpg agent:
>
>    ```sh
>    gpgconf --launch gpg-agent
>    ```
>
> 1. Check the keys have been imported correctly:
>
>    ```sh
>    $ gpg --export-ssh-key 'Johnny B. Good'
>    ssh-rsa AAAAB3NzaC…7SD8UQ== openpgp:0x7BB65DA2
>    $ ssh-add -L
>    ssh-rsa AAAAB3NzaC…7SD8UQ== (none)
>    ```
>
> </details>

### Share GPG-SSH keys

Run `ssh-add -L` to list one's public keys, then copy them over manually to the remote host.\
Alternatively, use `ssh-copy-id` as one would normally do.

## Troubleshooting

### `gpg failed to sign the data; fatal: failed to write commit object`

**Context:**

- `git` is instructed to sign a commit with `gpg`.
- `git commit` fails with the following error:

  > ```txt
  > gpg failed to sign the data
  > fatal: failed to write commit object
  > ```

- Pinentry should have prompted to input the key's passphrase, but the prompt did **not** appear.

**Cause:**

The environment variable `GPG_TTY` was not set and Pinentry could not reach the terminal session to prompt for the key's
passphrase.

**Solution:**

Make sure the environment variable `GPG_TTY` is set to the current TTY:

```sh
export GPG_TTY=$(tty)
```

### `sign_and_send_pubkey: signing failed for … from agent: agent refused operation`

**Context:**

- `git pull` fails with the following error:

  > ```txt
  > sign_and_send_pubkey: signing failed for … from agent: agent refused operation
  > user@git.server.fqdn: Permission denied (publickey).
  > fatal: Could not read from remote repository.
  > ```

- The repository is configured to connect to the remote using SSH.
- `ssh` is instructed to use a GPG key for authentication.
- Said GPG key is accepted for the user on the Git server.
- Pinentry should have prompted to input the key's passphrase, but the prompt did **not** appear.

**Solution:**

- Make sure the environment variable `GPG_TTY` is set to the current TTY:

  ```sh
  export GPG_TTY=$(tty)
  ```

- Reload the GPG agent for good measure:

  ```sh
  gpg-connect-agent reloadagent '/bye'
  ```

### New configuration settings are ineffective

**Cause:**

If already running, the GPG agent is still using the old configuration.\
Changing the configuration file now will have no effect.

**Solution:**

Reload the GPG agent:

```sh
gpg-connect-agent reloadagent '/bye'
```

## Further readings

- [Commonly seen problems]
- [Unattended key generation]
- [OpenPGP best practices]
- [GNU/Linux crypto series]

### Sources

- [Decrypt multiple openpgp files in a directory]
- [ask redhat]
- [how can i remove the passphrase from a gpg2 private key?]
- [How to enable SSH access using a GPG key for authentication]
- [gpg failed to sign the data fatal: failed to write commit object]
- [Can you manually add a comment to a PGP public key block and not break it?]
- [How to renew a (soon to be) expired GPG key]
- [Renew GPG key]
- [Archlinux's GnuPG wiki page]
- [GPG agent for SSH authentication]
- [Modify .gnupg home directories]
- [Stick with security: YubiKey, SSH, GnuPG, macOS]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Allow the SSH agent to use GPG (sub)keys]: #allow-the-ssh-agent-to-use-gpg-subkeys
[Create keys or subkeys capable of authenticating]: #create-keys-or-subkeys-capable-of-authenticating
[Trust keys]: #trust-keys

<!-- Upstream -->
[commonly seen problems]: https://www.gnupg.org/documentation/manuals/gnupg/Common-Problems.html
[modify .gnupg home directories]: https://www.gnupg.org/documentation/manuals/gnupg/gpgconf.html
[unattended key generation]: https://www.gnupg.org/documentation/manuals/gnupg/Unattended-GPG-key-generation.html

<!-- Others -->
[archlinux's gnupg wiki page]: https://wiki.archlinux.org/title/GnuPG
[ask redhat]: https://access.redhat.com/solutions/2115511
[can you manually add a comment to a pgp public key block and not break it?]: https://stackoverflow.com/questions/58696139/can-you-manually-add-a-comment-to-a-pgp-public-key-block-and-not-break-it#58696634
[decrypt multiple openpgp files in a directory]: https://stackoverflow.com/questions/18769290/decrypt-multiple-openpgp-files-in-a-directory/42431810#42431810
[gnu/linux crypto series]: https://blog.sanctum.geek.nz/series/gnu-linux-crypto/
[gpg agent for ssh authentication]: https://mlohr.com/gpg-agent-for-ssh-authentication-update/
[gpg failed to sign the data fatal: failed to write commit object]: https://stackoverflow.com/questions/39494631/gpg-failed-to-sign-the-data-fatal-failed-to-write-commit-object-git-2-10-0#42265848
[how can i remove the passphrase from a gpg2 private key?]: https://unix.stackexchange.com/a/550538
[how to enable ssh access using a gpg key for authentication]: https://opensource.com/article/19/4/gpg-subkeys-ssh
[how to renew a (soon to be) expired gpg key]: https://filipe.kiss.ink/renew-expired-gpg-key/
[openpgp best practices]: https://help.riseup.net/en/security/message-security/openpgp/gpg-best-practices
[renew gpg key]: https://gist.github.com/krisleech/760213ed287ea9da85521c7c9aac1df0
[stick with security: yubikey, ssh, gnupg, macos]: https://evilmartians.com/chronicles/stick-with-security-yubikey-ssh-gnupg-macos
