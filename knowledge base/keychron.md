# Keychron

1. set the keyboard to _Windows mode_ using the side switch

1. hold `Fn + X + L` for 4 seconds to set the function key row to _fn mode_

1. ensure the `hid_apple` module is loaded

   ```shell
   sudo modprobe hid_apple

   # load at boot
   echo 'hid_apple' | sudo tee /etc/modules-load.d/keychron.conf
   ```

1. configure the keyboard's _fn mode_:

   ```shell
   echo 0 | sudo tee /sys/module/hid_apple/parameters/fnmode

   # load at boot
   echo 'options hid_apple fnmode=0' | sudo tee /etc/modprobe.d/keychron.conf
   ```

## Further readings

- [K8 keyboard user manual]
- [Keychron fn keys in Linux]
- [Apple Keyboard] on the [Archlinux wiki]

[apple keyboard]: https://wiki.archlinux.org/index.php/Apple_Keyboard
[k8 keyboard user manual]: https://www.keychron.com/pages/k8-keyboard-user-manual
[keychron fn keys in linux]: https://mikeshade.com/posts/keychron-linux-function-keys

[archlinux wiki]: https://wiki.archlinux.org
