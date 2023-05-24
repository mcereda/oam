# Linux kernel modules

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Permanent modules configuration](#permanent-modules-configuration)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Show what kernel modules are currently loaded.
lsmod

# List all modules built into the currently running kernel.
cat "/lib/modules/$(uname -r)/modules.builtin"

# List all available modules.
find "/lib/modules/$(uname -r)" -type f -name '*.ko*'

# Show information about a module.
modinfo 'module_name'

# List the options set for loaded modules.
systool -v -m 'module_name'

# Show the comprehensive configuration of modules.
modprobe -c
modprobe -c | grep 'module_name'

# List the dependencies of modules or aliases.
# Includes the module itself.
modprobe --show-depends 'module_name'

# Load modules.
modprobe 'module_name'
modprobe 'module_name' 'parameter_1=value' 'parameter_n=value'

# Load modules by file name.
# For those not installed in "/usr/lib/modules/$(uname -r)/".
insmod 'file_name' 'arg_1' 'arg_n'

# Unload modules.
modprobe -r 'module_name'
rmmod 'module_name'
```

## Permanent modules configuration

Write the options in a `.conf` file in `/etc/modprobe.d/`:

```conf
# /etc/modprobe.d/raspi-wifi-workaround.conf
options brcmfmac roamoff=1 feature_disable=0x82000
```

## Further readings

## Sources

All the references in the [further readings] section, plus the following:

- The [Kernel module][arch wiki kernel module] page in the [Arch wiki]
- The [Kernel modules][gentoo wiki kernel modules]

<!-- project's references -->

<!-- internal references -->
[further readings]: #further-readings

<!-- external references -->
[arch wiki]: https://wiki.archlinux.org
[arch wiki kernel module]: https://wiki.archlinux.org/title/Kernel_module
[gentoo wiki]: https://wiki.gentoo.org/wiki/Main_Page
[gentoo wiki kernel modules]: https://wiki.gentoo.org/wiki/Kernel_Modules
