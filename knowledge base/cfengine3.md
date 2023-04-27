# CFEngine

## Table of contents <!-- omit in toc -->

1. [TL:DR](#tldr)
1. [Installation](#installation)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL:DR

| Command     | Configuration            |
| ----------- | ------------------------ |
| `cf-remote` | `~/.cfengine/cf-remote/` |

```sh
# List packages available for download.
cf-remote list

# Add hosts to groups.
# Will allow to use groups in other commands.
cf-remote save -H 'root@cfengine.lan' --role 'hub' --name 'hubs-group-name'
cf-remote save -H 'user@client.lan' --role 'client' --name 'clients-group-name'

# Show hosts spawned by `cf-remote` or added to it.
cf-remote show
cf-remote show --ansible-inventory

# Get info about hosts.
cf-remote info -H 'host-alias'

# Bootstrap remote hosts.
cf-remote install -B 'hub'
cf-remote --log-level 'INFO' install -B 'hub'

# Install a specific edition on remote hosts.
cf-remote install -E 'community' -c 'client'
cf-remote install -E 'enterprise' --hub 'hub'

# Reset `cf-remote` settings.
rm -r "${HOME}/.cfengine/cf-remote"

# Print the contents of DB files.
cf-check dump

# Assess the health of one or more DB files.
cf-check diagnose

# Diagnose databases, then backup and delete any one found corrupted.
cf-check repair
```

## Installation

On the development machine:

```sh
pip3 install 'cfbs' 'cf-remote'
cf-remote save -H 'root@cfengine.lan' --role 'hub' --name 'hub'
cf-remote install --hub 'hub' --bootstrap 'hub'
```

## Further readings

- [Website]
- [Documentation]

## Sources

All the references in the [further readings] section, plus the following:

<!-- project's references -->
[documentation]: https://docs.cfengine.com/docs/master/
[website]: https://cfengine.com/

<!-- internal references -->
[further readings]: #further-readings

<!-- external references -->
