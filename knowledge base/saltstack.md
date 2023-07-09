# Saltstack

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Key management](#key-management)
1. [Execute commands on minions](#execute-commands-on-minions)
1. [Targeting](#targeting)
1. [States](#states)
   1. [Create states](#create-states)
   1. [Apply states](#apply-states)
1. [The Top file](#the-top-file)
   1. [Create the Top file](#create-the-top-file)
1. [Formulas repo](#formulas-repo)
1. [Batch size](#batch-size)
1. [Terminology](#terminology)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# View all minion connections with their status.
salt-key --list all

# Accept minions' keys.
salt-key --accept='key'
salt-key --accept-all

# Test minions for reachability.
salt '*' test.ping
salt -L 'minion-1,minion-2' test.ping
salt --batch-size 10 '*' test.ping

# Run a shell command.
salt '*' cmd.run 'ls -l /etc'
salt -G 'os:Ubuntu' cmd.run 'echo bye'

# Show disk usage.
salt '*' disk.usage
salt 'minion-1' disk.usage

# Install packages.
salt '*' pkg.install 'cowsay'
salt -E 'minion[0-9]' pkg.install 'parallel'

# List network interfaces.
salt '*' network.interfaces
salt -C 'G@os:Ubuntu and minion* or S@192.168.50.*' network.interfaces
```

## Key management

Will use `salt-key`.  
This needs to be done on the **master** host.

- View all minion connections and whether the connection is accepted, rejected, or pending:

  ```sh
  salt-key --list all
  ```

- Before a minion can connect, you must accept its key:

  ```sh
  salt-key --accept='key'
  salt-key --accept-all
  ```

## Execute commands on minions

**After** you have accepted each key, you can send a command from your master host.

All managed systems simultaneously and immediately execute the command, then return the output to the master.

```sh
# Test minions for reachability.
salt '*' test.ping

# Run a shell command.
salt '*' cmd.run 'ls -l /etc'

# Show disk usage.
salt '*' disk.usage

# Install a package.
salt '*' pkg.install cowsay

# List network interfaces.
salt '*' network.interfaces
```

## Targeting

_Targeting_ is how you select minions when running commands, applying configurations, and when doing almost anything else in SaltStack that involves a minion.

```sh
# Target specific minions.
salt 'minion1' disk.usage
salt -L 'minion1,minion2' test.ping

# Target a set of minions using globbing.
salt 'minion*' disk.usage

# Target a set of minions using the grains system.
salt -G 'os:Ubuntu' test.ping

# Target a set of minion using regular expressions.
salt -E 'minion[0-9]' test.ping

# Mix them all up.
salt -C 'G@os:Ubuntu and minion* or S@192.168.50.*' test.ping
```

## States

SaltStack configuration management lets you create re-usable configuration templates, called _states_, that describe everything required to put a system component or application into a known configuration.<br/>
States are described using YAML, making them simpler to create and read.

Commands in state files are executed from top to bottom. The requisite system lets you explicitly determine the order.

### Create states

Just create a YAML file like this:

```yaml
install_network_packages:
  pkg.installed:
    - pkgs:
        - rsync
        - lftp
        - curl
```

and give it the `.sls` extension.

### Apply states

Use the `state.apply` command to apply a state from the command line on the master host.

```sh
salt 'minion2' state.apply 'nettools'
```

It will return an output that will list the changes made by the state.

The functions are idempotent, so applying the state twice will return an output that says everything is already OK and no changes have been made.

## The Top file

Top files apply multiple state files to minions. What states are applied to each system are determined by the targets that are specified in the Top file.

### Create the Top file

Each system can receive multiple configurations.<br/>
Start with the most general configurations, and work your way down to the specifics.

Targets are used within the Top file to define which states are applied to which minion.<br/>
When the Top file is evaluated, minions execute all states that are defined for **any** target they match.

For example, if you apply a Top file like this one:

```yaml
base:
  '*':
    - vim
    - scripts
    - users
  '*web*':
    - apache
    - python
    - django
  '*db*':
    - mysql
```

a system with a minion ID of `atl-web4-prod` would apply the `vim`, `scripts`, `users`, `apache`, `python`, and `django` states.

Now create the following `top.sls` file:

```yaml
base:
  '*':
    - common
  'minion1':
    - nettools
```

and, on your master, run the following command to apply the Top file:

```sh
salt '*' state.apply
```

`minion1` and `minion2` will both apply the `common` state, and `minion1` will also apply the `nettools` state.

## Formulas repo

The Salt Community provides a vast repository of Formulas at <https://github.com/saltstack-formulas>.

## Batch size

Limit how many systems are updated at once using the `--batch-size` option:

```sh
salt --batch-size 10 '*' state.apply
```

## Terminology

| Term | Definition |
| ---- | ---------- |
| Formula           | A collection of Salt state and Salt pillar files that configure an application or system component. Most formulas are made up of several Salt states spread across multiple Salt state files. |
| State             | A reusable declaration that configures a specific part of a system. Each Salt state is defined using a state declaration. |
| State Declaration | A top level section of a state file that lists the state function calls and arguments that make up a state. Each state declaration starts with a unique ID. |
| State Functions   | Commands that you call to perform a configuration task on a system. |
| State File        | A file with an SLS extension that contains one or more state declarations. |
| Pillar File       | A file with an SLS extension that defines custom variables and data for a system. |

## Further readings

- [Installation]
- [States]
- [Targeting]
- [Top files][top]

## Sources

All the references in the [further readings] section, plus the following:

<!-- upstream -->
[installation]: https://docs.saltstack.com/en/getstarted/fundamentals/install.html
[states]: https://docs.saltstack.com/en/getstarted/fundamentals/states.html
[targeting]: https://docs.saltstack.com/en/getstarted/fundamentals/targeting.html
[top]: https://docs.saltstack.com/en/getstarted/fundamentals/top.html

<!-- internal references -->
[further readings]: #further-readings

<!-- external references -->
