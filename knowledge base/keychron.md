# Keychron

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

1. set the keyboard to _Windows mode_ using the side switch

1. hold `Fn + X + L` for 4 seconds to set the function key row to _fn mode_

1. ensure the `hid_apple` module is loaded

   ```sh
   sudo modprobe hid_apple

   # load at boot
   echo 'hid_apple' | sudo tee /etc/modules-load.d/keychron.conf
   ```

1. configure the keyboard's _fn mode_:

   ```sh
   echo 0 | sudo tee /sys/module/hid_apple/parameters/fnmode

   # load at boot
   echo 'options hid_apple fnmode=0' | sudo tee /etc/modprobe.d/keychron.conf
   ```

## Further readings

- [K8 keyboard user manual]

[k8 keyboard user manual]: https://www.keychron.com/pages/k8-keyboard-user-manual

## Sources

- [Keychron fn keys in Linux]
- [Apple Keyboard] on the [Archlinux wiki]

<!--
  References
  -->

<!-- Others -->
[apple keyboard]: https://wiki.archlinux.org/index.php/Apple_Keyboard
[archlinux wiki]: https://wiki.archlinux.org
[keychron fn keys in linux]: https://mikeshade.com/posts/keychron-linux-function-keys
