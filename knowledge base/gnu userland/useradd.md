# The `useradd` command

Creates new users.

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Create *regular* (non-system) users.
sudo useradd 'username'
sudo useradd -p 'encrypted password' 'username'
sudo useradd --password 'encrypted password' 'username'

# Create *system* users without an home directory.
sudo useradd -r 'username'
sudo useradd --system 'username'

# Specify the user ID.
sudo useradd -u '1005' …
sudo useradd --uid '1002' …

# Specify the primary group.
sudo useradd -g '100' …
sudo useradd --gid 'users' …

# Specify the expiration date.
sudo useradd -e '2022-10-10' …
sudo useradd --expiredate '2022-04-13' …

# Specify the login shell.
sudo useradd -s '/bin/bash' …
sudo useradd --shell '/usr/bin/fish' …

# Add the new users to *additional* groups.
sudo useradd -G 'audio' …
sudo useradd --groups 'video,wheel' …

# Force the creation of the new users' default home directory.
sudo useradd -m …
sudo useradd --create-home …

# Avoid the creation of the new users' default home directory.
sudo useradd -M …
sudo useradd --no-create-home …

# Force the creation of a group with the same name as the users.
sudo useradd -U …
sudo useradd --user-group …

# Avoid the creation of a group with the same name as the users.
sudo useradd -N …
sudo useradd --no-user-group …

# Create the users' home directory with specific template files.
sudo useradd -k 'path/to/template/directory' -m …
sudo useradd --skel 'path/to/template/directory' -m …


# Create a regular user with a home directory and the 'users' group as its
# primary group.
sudo useradd -mN -g 'users' -p '1234' 'user'
```

## Sources

- [cheat.sh]

<!--
  References
  -->

<!-- Others -->
[cheat.sh]: https://cheat.sh/useradd
