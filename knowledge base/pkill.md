# pkill

> TODO

Command-line tools that sends signals to the processes of a running program based on given criteria.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Basically a wrapper around `pgrep` and `kill`.

Part of the `procps` (or `procps-ng`) package, which is pre-installed on nearly all Linux distributions.

The processes can be specified by:

- Their **full** or **partial** name.
- A user running the process.
- Other attributes.

Returns 0 when at least one running process matched the requested pattern. Otherwise, its exit code is `1`.

<details>
  <summary>Setup</summary>

```sh
apt install 'procps'
brew install 'proctools'  # or brew install 'pkill'
dnf install 'procps-ng'
yum install 'procps-ng'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Gracefully stop all processes of programs matching the given pattern
pkill 'pattern'
pkill -15 'pattern'
pkill -TERM 'pattern'
pkill -SIGTERM 'pattern'
pkill --signal 'TERM' 'pattern'

# Display what processes are sent signals
pkill -e …
pkill --echo …

# Only kill processes of specific users' *real* id
pkill -u 'mark' …
pkill --uid 'mark,john' …
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
pkill -HUP 'nginx'
pkill --signal 'TERM' --exact 'yes'
pkill '^ssh$'
pkill -9 -f "ping 8.8.8.8"
pkill -KILL -u 'mike' 'gdm'
```

</details>

## Further readings

- [Website]
- [Codebase]

### Sources

- [Documentation]
- [Pkill Command in Linux]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/project/
[Documentation]: https://website/docs/
[Website]: https://website/

<!-- Others -->
[Pkill Command in Linux]: https://linuxize.com/post/pkill-command-in-linux/
