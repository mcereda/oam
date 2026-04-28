# The `at` utility

> TODO

Intro

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

> [!important]
> For jobs to fire, `at` requires the `atd` daemon to be running.<br/>
> On macOS the daemon is **disabled** by default. Consider enabling it if needing to run quick, one-off commands
> sporadically; reach for `launchd` (macOS' native scheduler, via `launchctl` and a plist file) for more control.

```sh
# Time formats
at 10:00 AM          # today at 10am (or tomorrow if past 10am)
at now + 5 minutes   # five minutes from now
at midnight          # tonight at 00:00
at 4pm + 3 days      # three days from now at 4pm
at 10:00 AM Jul 31   # specific date
at now + 1 hour      # run a script in 1 hour
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Run a script in 1 hour.
at -f 'myscript.sh' now + 1 hour

# Schedule a command via interactive prompt.
$ at 14:30
at> echo "Hello at 2:30 PM" > /tmp/hello.txt
at> <EOT>

# Schedule a script execution via pipe.
echo "/path/to/backup.sh" | at 03:00 tomorrow
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Website]
- [Codebase]
- [Blog]

### Sources

- [Documentation]
- [macOS]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[macOS]: macos/README.md

<!-- Files -->
<!-- Upstream -->
[Blog]: https://FIXME.fqdn/blog/
[Codebase]: https://github.com/FIXME
[Documentation]: https://FIXME.fqdn/docs/
[Website]: https://FIXME.fqdn/

<!-- Others -->
