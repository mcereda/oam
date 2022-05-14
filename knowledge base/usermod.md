# Usermod

## TL;DR

```sh
# Change a user's primary group.
sudo usermod -g docker bob

# Add/remove a user to/from supplementary groups.
sudo usermod -aG wheel carly
sudo usermod --append --groups kvm,video,audio alice
sudo usermod -rG sudo,admin eve

# Change a user's login name
sudo usermod --login to-stephen from-micha

# Change a user's ID.
sudo usermod --uid 1001 hugo

# Change a user's shell.
sudo usermod --shell /usr/bin/zsh rick

# Change a user's password.
sudo usermod -p encryptedPassword john

# Lock/unlock a user.
sudo usermod -L damian
sudo usermod -U luke

# Change a user's home directory.
sudo usermod --move-home --home path/to/new_home lonny
```

## Sources

- [cheat.sh]

[cheat.sh]: cheat.sh/usermod
