# NixOS

Linux distribution based on [Nix].

1. [TL;DR](#tldr)
1. [Automatic Upgrades](#automatic-upgrades)
1. [Automatic package cleanup](#automatic-package-cleanup)
1. [Further readings](#further-readings)

## TL;DR

Refer [Nix] for the package manager's commands.

The `/etc/nixos/configuration.nix` file contains the current configuration of the local system.<br/>
Execute `nixos-rebuild switch` **as root** whenever one changes something in there to apply the changes.

When multiple modules define an option, NixOS will try to **merge** all the definitions.

System configurations are stored in the `/nix/var/nix/profiles/system` profile.

<details>
  <summary>Usage</summary>

```sh
# Open the manual in a browser window.
nixos-help

# Inspect the system configuration.
nixos-rebuild repl

# Apply changes to the system configuration.
# Only builds the configuration.
sudo nixos-rebuild build
# Switches the running system to the new configuration.
# Does *not* make it the default for booting.
sudo nixos-rebuild test
# Makes it the default for booting.
# Does *not* apply it to the running system.
sudo nixos-rebuild boot
# Makes it the default configuration for booting.
# Also tries to apply it to the running system.
sudo nixos-rebuild switch
# Make the new configuration show as an entry in GRUB.
sudo nixos-rebuild switch -p 'new entry'

# Upgrade NixOS to the latest version in the chosen channel.
# Equivalent to `sudo nix-channel --update 'nixos' && nixos-rebuild switch`.
sudo nixos-rebuild switch --upgrade

# Test a new configuration in a sandbox.
# Requires hardware virtualization.
# Builds and runs a QEMU VM containing the desired configuration.
sudo nixos-rebuild build-vm && ./result/bin/run-*-vm
```

```sh
# Prefer using the '--attr' option with nix.
# The normal command (e.g. `nix-env -i 'k3s'`) got always killed in tests.
nix-env --install --attr 'nixos.k3s'
nix-env --upgrade --attr 'nixos.parallel'
```

</details>

## Automatic Upgrades

Enable the `nixos-upgrade.service` to automatically keep a NixOS system up-to-date by adding the following to the
`/etc/nixos/configuration.nix` file:

```plaintext
{
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;
}
```

If the `allowReboot` option is set to `false`, the service just runs `nixos-rebuild switch --upgrade` to upgrade the
system to the latest version in the current channel.<br/>
If it is set to `true`, then the system will also automatically reboot if the new generation contains any different
initrd, kernel or kernel module.

Specify a channel explicitly in the same file, e.g.:

```plaintext
{ system.autoUpgrade.channel = "https://channels.nixos.org/nixos-24.05"; }
```

Check when the service runs by looking at the output of `systemctl list-timers 'nixos-upgrade.timer'`.

## Automatic package cleanup

Enable `nix-gc.service` to automatically remove old, unreferenced packages.

One can set the system up to run this unit automatically at certain points in time:

```plaintext
{
  nix.gc.automatic = true;
  nix.gc.dates = "03:15";
}
```

## Further readings

- [Website]
- [Manual]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[nix]: nix.md

<!-- Upstream -->
[manual]: https://nixos.org/manual/nixos/stable/
[website]: https://nixos.org
