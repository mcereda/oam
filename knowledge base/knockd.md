# knockd

Port-knock server. It listens to all traffic on a network interface, looking for special _knock_ sequences of port-hits. These ports do **not** need to be open -- `knockd` listens at the link-layer level, so it can even see traffic which is destined to a closed port.

When the server detects a specific sequence of port-hits, it runs a command defined in its configuration file. This can be used to open up holes in a firewall for quick access.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
1. [Sources](#sources)

## TL;DR

Server side:

```sh
# Install `knockd`.
sudo apt install 'knockd'
brew install 'knockd'
sudo dnf install 'knock-server'
sudo zypper install 'knockd'

# Configure the sequence and its effects.
sudo vim '/etc/knockd.conf'

# Enable the service.
sudo systemctl enable --now 'knockd.service'

# Keep an eye on the logs to see if the sequence is working.
sudo journalctl -xe -u 'knockd.service'
```

Client side:

```sh
# Install `knock`.
sudo apt install 'knockd'
brew install 'knockd'
sudo dnf install 'knock'
sudo zypper install 'knock'

# Send the command.
# If ':protocol' is not given, defaults to 'tcp'; defaults to 'udp' if the '-u'
# option is specified.
knock '123.456.789.012' '2222' '3333:udp' '4444'
knock -vu 'example.fqdn' '2222:tcp' '3333' '4444:tcp'
```

## Configuration

`knockd`'s default configuration file is `/etc/knockd.conf`.

Each knock/event begins with a title marker in the form `[name]`, with it being the name of the event that will appear in the log.<br/>
`[options]` is a special marker used to define `knockd`'s **global** options.

```ini
[options]
	UseSyslog
	Interface = enp0s2

# Different sequences for opening and closing.
[openSSH]
    sequence    = 7000,8000,9000
    seq_timeout = 10
    tcpflags    = syn
    command     = /usr/sbin/iptables -A INPUT -s %IP% -j ACCEPT
[closeSSH]
    sequence    = 9000,8000,7000
    seq_timeout = 10
    tcpflags    = syn
    command     = /usr/sbin/iptables -D INPUT -s %IP% -j ACCEPT

# Single sequence for opening, automatic close after 'cmd_timeout' seconds.
# If a sequence setting contains the `cmd_timeout` statement, the `stop_command`
# will be automatically issued after that amount of seconds.
[openClose7777]
	sequence      = 2222:udp,3333:tcp,4444:udp
	seq_timeout   = 15
	tcpflags      = syn
	cmd_timeout   = 10
	start_command = /usr/bin/firewall-cmd --add-port=7777/tcp --zone=public
	stop_command  = /usr/bin/firewall-cmd --remove-port=7777/tcp --zone=public
```

Sequences can also be defined in files.

Check the [`knockd(1)`][knockd man page] man page for all the information.

## Sources

- [How to use port knocking to secure SSH service in Linux]
- [Server][knockd man page]'s man page
- [Client][knock man page]'s man page

<!--
  References
  -->

<!-- Others -->
[how to use port knocking to secure ssh service in linux]: https://www.tecmint.com/port-knocking-to-secure-ssh/
[knockd man page]: https://linux.die.net/man/1/knockd
[knock man page]: https://linux.die.net/man/1/knock
