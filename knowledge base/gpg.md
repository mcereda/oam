# GnuPG

## TL;DR

```shell
# generate a new key
gpg --gen-key
gpg --generate-key
gpg --full-generate-key
gpg --expert --full-generate-key

# unattended key generation
# the non-interactive (--batch) option requires a settings file
gpg --generate-key --batch setting.txt
gpg --generate-key --batch <<-EOF
	…
EOF

# list existing keys
gpg --list-keys
gpg --list-keys --keyid-format short
gpg --list-secret-keys

# delete a key from the keyring
# the non-interactive (--batch) option requires the key fingerprint
gpg --delete-secret-key recipient
gpg --delete-key recipient
gpg --delete-keys --batch fingerprint

# get the short id of the signing key only for a user
# primarily used for git config
gpg --list-keys --keyid-format short recipient \
 | grep --extended-regexp \
     '^pub[[:blank:]]+[[:alnum:]]+/[[:alnum:]]+[[:blank:]].*\[[[:upper:]]*S[[:upper:]]*\]' \
 | awk '{print $2}' \
 | cut -d '/' -f 2

# get a key fingerprint information
gpg --fingerprint
gpg --fingerprint recipient

# encrypt a file
gpg --output file.out.gpg --encrypt --recipient recipient file.in
gpg -o file.out.gpg --encrypt --local-user sender --recipient recipient file.in

# decrypt a file
gpg --output file.out --decrypt file.gpg

# import keys from a file
gpg --import keys.asc

# export keys to a file
gpg --armor --export > all.public-keys.asc
gpg --armor --export recipient > recipient.public-keys.asc
gpg --armor --export-secret-keys > all.private-keys.asc
gpg --armor --export-secret-keys recipient > recipient.private-keys.asc

# generate a revoke certificate
gpg --gen-revoke

# install on mac os x
# choose one
brew install --cask gpg-suite-no-mail
brew install gnupg
```

## Encryption

```shell
# single file
gpg --output $DB.key.gpg --encrypt --recipient $RECIPIENT $DB.key

# all found files
find . -type f -name secret.txt \
  -exec gpg --batch --yes --encrypt-files --recipient $RECIPIENT {} ';'
```

## Decryption

```shell
# single file
gpg --output $DB.key --decrypt $DB.key.gpg

# all found files
find . -type f -name "*.gpg" -exec gpg --decrypt-files {} +
```

The second command will create the decrypted version of all files in the same directory. Each file will have the same name of the encrypted version, minus the `.gpg` extension.

## Key export

As the original user, export all public keys to a base64-encoded text file and create an encrypted version of that file:

```shell
gpg --armor --export > mypubkeys.asc
gpg --armor --export email > mypubkeys-email.asc
gpg --armor --symmetric --output mysecretatedpubkeys.sec.asc mypubkeys.asc
```

Export all encrypted private keys (which will also include corresponding public keys) to a text file and create an encrypted version of that file:

```shell
gpg --armor --export-secret-keys > myprivatekeys.asc
gpg --armor --symmetric --output mysecretatedprivatekeys.sec.asc myprivatekeys.asc
```

Optionally, export gpg's trustdb to a text file:

```shell
gpg --export-ownertrust > otrust.txt
```

## Key import

As the new user, execute `gpg --import` commands against the two `.asc` files, or the decrypted content of those files, and then check for the new keys with `gpg -k` and `gpg -K`, e.g.:

```shell
gpg --output myprivatekeys.asc --decrypt mysecretatedprivatekeys.sec.asc
gpg --import myprivatekeys.asc
gpg --output mypubkeys.asc --decrypt mysecretatedpubkeys.sec.asc
gpg --import mypubkeys.asc
gpg --list-secret-keys
gpg --list-keys
```

Optionally import the trustdb file as well:

```shell
gpg --import-ownertrust otrust.txt
```

## Key trust

```shell
$ gpg --edit-key $FINGERPRINT
gpg> trust
gpg> quit
```

## Unattended key generation

```shell
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

```shell
$ gpg --edit-key $FINGERPRINT
gpg> passwd
gpg> quit
```

## Put comments in a message or file

One can put comments in an armored ASCII message or key block using the `Comment` keyword for each line:

```plaintext
-----BEGIN PGP MESSAGE-----
Comment: …
Comment: …

hQIMAwbYc…
-----END PGP MESSAGE-----
```

OpenPGP defines all text to be in UTF-8, so a comment may be any UTF-8 string.  
The whole point of armoring, however, is to provide seven-bit-clean data, so if a comment has characters that are outside the US-ASCII range of UTF they may very well not survive transport.

## Troubleshooting

### `gpg failed to sign the data; fatal: failed to write commit object`

**Problem:**

- `git` is instructed to sign a commit with `gpg`
- `git commit` fails with the following error:

  > ```plaintext
  > gpg failed to sign the data
  > fatal: failed to write commit object
  > ```

**Solution:** if `gnupg2` and `gpg-agent` 2.x are used, be sure to set the environment variable `GPG_TTY`:

```shell
export GPG_TTY=$(tty)
```

## Further readings

- [Decrypt multiple openpgp files in a directory]
- [ask redhat]
- [how can i remove the passphrase from a gpg2 private key?]
- [Unattended key generation]
- [How to enable SSH access using a GPG key for authentication]
- [gpg failed to sign the data fatal: failed to write commit object]
- [Can you manually add a comment to a PGP public key block and not break it?]

[ask redhat]: https://access.redhat.com/solutions/2115511
[can you manually add a comment to a pgp public key block and not break it?]: https://stackoverflow.com/questions/58696139/can-you-manually-add-a-comment-to-a-pgp-public-key-block-and-not-break-it#58696634
[decrypt multiple openpgp files in a directory]: https://stackoverflow.com/questions/18769290/decrypt-multiple-openpgp-files-in-a-directory/42431810#42431810
[gpg failed to sign the data fatal: failed to write commit object]: https://stackoverflow.com/questions/39494631/gpg-failed-to-sign-the-data-fatal-failed-to-write-commit-object-git-2-10-0#42265848
[how can i remove the passphrase from a gpg2 private key?]: https://unix.stackexchange.com/a/550538
[how to enable ssh access using a gpg key for authentication]: https://opensource.com/article/19/4/gpg-subkeys-ssh
[unattended key generation]: https://www.gnupg.org/documentation/manuals/gnupg/Unattended-GPG-key-generation.html
