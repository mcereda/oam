# Swap

## TL;DR

```shell
# show the swap usage
swapon --show
free -h

# enable or disable a swap partition or file
sudo swapon /root/swapfile
sudo swapoff LABEL=swap
sudo swapoff /dev/sda2

# enable or disable *all* swap partition or file
sudo swapon -a
sudo swapoff --all

# chech what processes are swapping
# see the "si" (swap in) and "so" (swap out) columns
vmstat
vmstat --wide 1
```

## Swappiness

```shell
# change the current value
sudo sysctl vm.swappiness=10
sudo sysctl -w vm/swappiness=5

# persistent configuration
echo 'vm.swappiness=10'  | sudo tee -a /etc/sysctl.conf
echo 'vm.swappiness = 5' | sudo tee -a /etc/sysctl.d/99-swappiness.conf
```

## Swapfile

```shell
# add a swapfile
sudo fallocate -l 1G /swapfile   # or sudo dd if=/dev/zero of=/swapfile bs=1024 count=1048576
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab

# remove a swapfile
sudo swapoff -v /swapfile
sudo sed -i.bak '/\/swapfile/d' /etc/fstab
sudo rm /swapfile
```

## Further readings

- [create a linux swap file]
- [How to reload sysctl.conf variables on Linux]
- [How to empty swap if there is free RAM]

[create a linux swap file]: https://linuxize.com/post/create-a-linux-swap-file/
[how to reload sysctl.conf variables on linux]: https://www.cyberciti.biz/faq/reload-sysctl-conf-on-linux-using-sysctl/
[how to empty swap if there is free ram]: https://askubuntu.com/questions/1357/how-to-empty-swap-if-there-is-free-ram#1379
