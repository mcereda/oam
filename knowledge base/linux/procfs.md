# The `/proc` filesystem

Pseudo filesystem acting as an interface to internal data structures in the kernel.\
It can be used to obtain information about the system and to change certain kernel parameters at runtime (usually via
[`sysctl`][sysctl])

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

The running kernel populates `/proc` with data files containing information about itself and its environment.\
E.g., `/proc/cmdline` contains the kernel's command line from both the bootloader and the kernel's image, while
`/proc/meminfo` provides information about distribution and utilization of the system's memory.

Each running process adds a directory to `/proc/` named after its process ID, e.g. `/proc/1` for the init process or
the entrypoint of a container.\
A process can read files from **its own** `/proc/{{PID}}` directory with no extra permissions. Reading other processes'
files requires either having `CAP_SYS_PTRACE` capability with `PTRACE_MODE_READ` access permissions or `CAP_PERFMON`
capability.

Existing directories _can_ eventually be reused by processes spawning with the same PID.\
In this case, operations on file descriptors that correspond to dead processes just fail (usually with error code
`ESRCH`) and do **not** impact the new process.

`self` is a link, and points to the process reading the file system.\
`/proc/net` contains networking information.

`/proc/sys` also allows changing parameters within the kernel on runtime. Those last until the system is rebooted.\
Usually useful on development machines to tweak the values.\
Simply use `root` privileges to `echo` a new value into a file. Using `sysctl` does mostly the same.

<details>
  <summary>Usage</summary>

```sh
# Get information about a process.
cat '/proc/42/status'
cat "/proc/$(pgrep -o 'syncthing')/status"

# Get a process' currently mapped memory regions and their access permissions.
# 'smaps' files extend 'maps' with memory consumption
cat '/proc/4453/maps'
cat "/proc/$(pgrep -o 'bash')/smaps"
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Specify which CPUs can handle the IRQ.
echo '1' > '/proc/irq/10/smp_affinity'

# Avoid dumping all shared memory segments attached to pid 1234.
echo '0x31' > '/proc/1234/coredump_filter'

# Recover files of a running process.
cp "/proc/$(pgrep -n 'some-app')/exe" '/root/rescue/some-app/executable'
cp "/proc/$(pgrep -n 'some-app')/environ" '/root/rescue/some-app/'
cp "/proc/$(pgrep -n 'some-app')/cmdline" '/root/rescue/some-app/'
```

</details>

## Further readings

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[sysctl]: ../sysctl.md

<!-- Files -->
<!-- Upstream -->
[Documentation]: https://www.kernel.org/doc/html/latest/filesystems/proc.html

<!-- Others -->
