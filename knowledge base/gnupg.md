# GnuPG

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Encryption](#encryption)
1. [Decryption](#decryption)
1. [Key export](#key-export)
1. [Key import](#key-import)
1. [Key trust](#key-trust)
1. [Unattended key generation](#unattended-key-generation)
1. [Change a key's password](#change-a-keys-password)
1. [Put comments in a message or file](#put-comments-in-a-message-or-file)
1. [Use a GPG key for SSH authentication](#use-a-gpg-key-for-ssh-authentication)
    1. [Create an authentication subkey](#create-an-authentication-subkey)
    1. [Enable SSH to use the GPG subkey](#enable-ssh-to-use-the-gpg-subkey)
    1. [Share the GPG-SSH key](#share-the-gpg-ssh-key)
1. [Troubleshooting](#troubleshooting)
    1. [`gpg failed to sign the data; fatal: failed to write commit object`](#gpg-failed-to-sign-the-data-fatal-failed-to-write-commit-object)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# List existing keys.
gpg --list-keys
gpg --list-keys --keyid-format 'short'
gpg --list-secret-keys --with-keygrip --keyid-format '0xlong'

# Generate a new key.
gpg --gen-key
gpg --generate-key
gpg --full-generate-key
gpg --expert --full-generate-key

# Generate a new key unattended.
# The non-interactive (--batch) option requires a settings file.
gpg --generate-key --batch 'setting.txt'
gpg --generate-key --batch <<-EOF
	…
EOF

# Delete a key from the keyring.
# The non-interactive (--batch) option requires the key fingerprint.
gpg --delete-secret-key 'recipient'
gpg --delete-key 'recipient'
gpg --delete-keys --batch 'key_fingerprint'

# Get a key's fingerprint information.
gpg --fingerprint
gpg --fingerprint 'recipient'

# Encrypt files.
gpg -e -o 'file.out.gpg' -r 'recipient' 'file.in'
gpg --encrypt -o 'file.out.gpg' -u 'sender' -r 'recipient' 'file.in'
gpg --encrypt-files --batch -r 'recipient' 'file.in.1' 'file.in.N'
gpg -e --multifile --batch -r 'recipient' --yes 'file.in.1' 'file.in.N'

# Decrypt files.
gpg -d -o 'file.out' 'file.in.gpg'
gpg --decrypt-files --batch 'file.in.gpg.1' 'file.in.gpg.N'
gpg -d --multifile --batch --yes 'file.in.gpg.1' 'file.in.gpg.N'

# Import keys from a file.
gpg --import 'keys.asc'

# Export keys to a file.
gpg --armor --export > 'all.public-keys.asc'
gpg --armor --export recipient > 'recipient.public-keys.asc'
gpg --armor --export-secret-keys > 'all.private-keys.asc'
gpg --armor --export-secret-keys recipient > 'recipient.private-keys.asc'

# Generate a revoke certificate.
gpg --gen-revoke

# Get the short ID of the signing key only for a user.
# Primarily usable for git's signingKey configuration.
gpg --list-keys --keyid-format 'short' 'recipient' \
| grep --extended-regexp '^pub[[:blank:]]+[[:alnum:]]+/[[:alnum:]]+[[:blank:]].*\[[[:upper:]]*S[[:upper:]]*\]' \
| awk '{print $2}' \
| cut -d '/' -f 2

# Install on Mac OS X.
# Choose one.
brew install --cask 'gpg-suite-no-mail'
brew install 'gnupg'

# Integrate with the SSH agent.
export SSH_AUTH_SOCK="$(gpgconf --list-dirs 'agent-ssh-socket')" && \
gpgconf --launch 'gpg-agent'

# Integrate with Pinentry.
export GPG_TTY="$(tty)"
```

## Encryption

```sh
# Single file.
gpg --output 'file.out.gpg' --encrypt --recipient 'recipient' 'file.in'
gpg --armor --symmetric --output 'file.out.gpg' 'file.in'

# All files found.
find . -type 'f' -name 'secret.txt' \
  -exec gpg --batch --yes --encrypt-files --recipient 'recipient' {} ';'
```

## Decryption

```sh
# Single file.
gpg --output 'file.out' --decrypt 'file.in.gpg'

# All files found.
find . -type f -name "*.gpg" -exec gpg --decrypt-files {} +
```

The second command will create the decrypted version of all files in the same directory. Each file will have the same name of the encrypted version, minus the `.gpg` extension.

## Key export

As the original user, export all public keys to a base64-encoded text file and create an encrypted version of that file:

```sh
# Export.
gpg --armor --export > 'all.public-keys.asc'
gpg --armor --export 'recipient' > 'recipient.public-keys.asc'

# Encryption.
gpg --output 'file.out.gpg' --encrypt --recipient 'recipient' 'file.in'
gpg --armor --symmetric --output 'file.out.gpg' 'file.in'
```

Export all encrypted private keys (which will also include corresponding public keys) to a text file and create an encrypted version of that file:

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

## Key import

As the new user execute `gpg --import` commands against the secured files, or the decrypted content of those files, and then check for the new keys with `gpg -k` and `gpg -K`, e.g.:

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

## Key trust

```sh
$ gpg --edit-key 'key_fingerprint'
gpg> trust
gpg> quit
```

## Unattended key generation

> The non-interactive (--batch) option requires a settings file.

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

## Change a key's password

```sh
$ gpg --edit-key 'key_fingerprint'
gpg> passwd
gpg> quit
```

## Put comments in a message or file

One can put comments in an armored ASCII message or key block using the `Comment` keyword for each line:

```txt
-----BEGIN PGP MESSAGE-----
Comment: …
Comment: …

hQIMAwbYc…
-----END PGP MESSAGE-----
```

OpenPGP defines all text to be in UTF-8, so a comment may be any UTF-8 string.<br/>
The whole point of armoring, however, is to provide seven-bit-clean data, so if a comment has characters that are outside the US-ASCII range of UTF they may very well not survive transport.

## Use a GPG key for SSH authentication

> Shamelessly copied over from [How to enable SSH access using a GPG key for authentication].

This exercise will use a GPG subkey with only the authentication capability enabled to complete SSH connections.<br/>
You can create multiple subkeys as you would do for SSH key pairs.

### Create an authentication subkey

You should already have a GPG key. If you don't, read one of the many fine tutorials available on this topic.<br/>
You will create the subkey by editing your existing key **in expert mode** to get access to the appropriate options:

```sh
$ gpg2 --expert --edit-key 'key_fingerprint'
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
ssb  rsa2048/17E7403F18CB1123
     created: 2019-03-21  expires: never       usage: A
[ultimate] (1). Brian Exelbierd

gpg> quit
Save changes? (y/N) y
```

### Enable SSH to use the GPG subkey

When using SSH, `ssh-agent` is used to manage SSH keys. When using a GPG key, `gpg-agent` is used to manage GPG keys.<br/>
To get `gpg-agent` to handle requests from SSH, you need to enable its SSH support:

```sh
echo "enable-ssh-support" >> ~/.gnupg/gpg-agent.conf
```

You can avoid using `ssh-add` to load the keys pre-specifying which GPG keys to use in the `~/.gnupg/sshcontrol` file.<br/>
The entries in this file are keygrips—internal identifiers that `gpg-agent` uses to refer to the keys. A keygrip refers to both the public and private key.<br/>
To find the keygrip use `gpg -K --with-keygrip`, then add that line to the `~/.gnupg/sshcontrol` file:

```sh
$ gpg2 -K --with-keygrip
/home/bexelbie/.gnupg/pubring.kbx
------------------------------
sec   rsa2048 2019-03-21 [SC] [expires: 2021-03-20]
      96F33EA7F4E0F7051D75FC208715AF32191DB135
      Keygrip = 90E08830BC1AAD225E657AD4FBE638B3D8E50C9E
uid           [ultimate] Brian Exelbierd
ssb   rsa2048 2019-03-21 [E] [expires: 2021-03-20]
      Keygrip = 5FA04ABEBFBC5089E50EDEB43198B4895BCA2136
ssb   rsa2048 2019-03-21 [A]
      Keygrip = 7710BA0643CC022B92544181FF2EAC2A290CDC0E

$ echo 7710BA0643CC022B92544181FF2EAC2A290CDC0E >> ~/.gnupg/sshcontrol
```

Now tell SSH how to access `gpg-agent` by setting the value of the `SSH_AUTH_SOCK` environment variable.

```sh
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent
```

### Share the GPG-SSH key

Run `ssh-add -L` to list your public keys and copy them over manually to the remote host, or use `ssh-copy-id` as you would normally do.

## Troubleshooting

### `gpg failed to sign the data; fatal: failed to write commit object`

**Problem:**

- `git` is instructed to sign a commit with `gpg`
- `git commit` fails with the following error:

  > ```txt
  > gpg failed to sign the data
  > fatal: failed to write commit object
  > ```

**Solution:** if `gnupg2` and `gpg-agent` 2.x are used, be sure to set the environment variable `GPG_TTY`:

```sh
export GPG_TTY=$(tty)
```

## Further readings

- [Commonly seen problems]
- [Unattended key generation]

## Sources

All the references in the [further readings] section, plus the following:

- [Decrypt multiple openpgp files in a directory]
- [ask redhat]
- [how can i remove the passphrase from a gpg2 private key?]
- [How to enable SSH access using a GPG key for authentication]
- [gpg failed to sign the data fatal: failed to write commit object]
- [Can you manually add a comment to a PGP public key block and not break it?]
- [How to renew a (soon to be) expired GPG key]
- [Renew GPG key]

<!--
  References
  -->

<!-- Upstream -->
[commonly seen problems]: https://www.gnupg.org/documentation/manuals/gnupg/Common-Problems.html
[unattended key generation]: https://www.gnupg.org/documentation/manuals/gnupg/Unattended-GPG-key-generation.html

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Others -->
[ask redhat]: https://access.redhat.com/solutions/2115511
[can you manually add a comment to a pgp public key block and not break it?]: https://stackoverflow.com/questions/58696139/can-you-manually-add-a-comment-to-a-pgp-public-key-block-and-not-break-it#58696634
[decrypt multiple openpgp files in a directory]: https://stackoverflow.com/questions/18769290/decrypt-multiple-openpgp-files-in-a-directory/42431810#42431810
[gpg failed to sign the data fatal: failed to write commit object]: https://stackoverflow.com/questions/39494631/gpg-failed-to-sign-the-data-fatal-failed-to-write-commit-object-git-2-10-0#42265848
[how can i remove the passphrase from a gpg2 private key?]: https://unix.stackexchange.com/a/550538
[how to enable ssh access using a gpg key for authentication]: https://opensource.com/article/19/4/gpg-subkeys-ssh
[how to renew a (soon to be) expired gpg key]: https://filipe.kiss.ink/renew-expired-gpg-key/
[renew gpg key]: https://gist.github.com/krisleech/760213ed287ea9da85521c7c9aac1df0
