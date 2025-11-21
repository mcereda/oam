# The `usermod` command

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Change users' primary group.
sudo usermod -g 'docker' 'bob'
sudo usermod --gid 'sudo' 'luke'

# Add/remove users to/from supplementary groups.
sudo usermod -aG 'wheel' 'carly'
sudo usermod --append --groups 'kvm,video,audio' 'alice'
sudo usermod -rG 'sudo,admin' 'eve'
sudo usermod --remove --groups 'proftpd' 'dina'

# Change users' login name.
sudo usermod -l 'to-stephen' 'from-michael'
sudo usermod --login 'to-floyd' 'from-rene'

# Change users' ID.
sudo usermod -u '1005' 'farra'
sudo usermod --uid '1001' 'hugo'

# Change users' login shell.
sudo usermod -s '/bin/zsh' 'rick'
sudo usermod --shell '/usr/bin/fish' 'morty'

# Change users' password.
sudo usermod -p 'encrypted password' 'john'
sudo usermod --password 'encrypted password' 'snow'

# Lock/unlock users.
sudo usermod -L 'damian'
sudo usermod --lock 'sergio'
sudo usermod -U 'ivan'
sudo usermod --unlock 'lez'

# Change users' home directory.
sudo usermod -md 'path/to/new/home' 'lenny'
sudo usermod --move-home --home 'path/to/new/home' 'lonny'
```

## Sources

- [cheat.sh]

<!--
  References
  -->

<!-- Others -->
[cheat.sh]: https://cheat.sh/usermod
