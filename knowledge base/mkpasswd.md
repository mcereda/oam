# Debian's mkpasswd

Crypts a given password using `crypt(3)`.

```sh
mkpasswd [OPTIONS]... [PASSWORD [SALT]]
```

## TL;DR

```sh
# List available encrypting methods.
mkpasswd -m -h

# Return a hash of a specific method.
mkpasswd -m 'nt' 'password'
mkpasswd -m 'sha512crypt' 'password'
```
