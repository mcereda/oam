# Vagrant


## TL;DR

```shell
# start a box
vagrant up

# connect to the box
vagrant ssh
# print the ssh config snippet to connect to the box
vagrant ssh-config

# (re)provision a box
vagrant provision
vagrant up --provision

# add a box
vagrant add archlinux/archlinux
vagrant add debian/testing64 --provider virtualbox

# list downloaded boxes
vagrant box list

# list outdated boxes
vagrant box outdated

# update a box
vagrant box update
vagrant box update --box generic/gentoo

# remove a box
vagrant box remove archlinux/archlinux

# install autocomplete
vagrant autocomplete install --bash
vagrant autocomplete install --zsh

# install a plugin
vagrant plugin install vagrant-disksize
```

## Usage

1. install using your package manager
1. create a box:

   ```shell
   [home]$ mkdir -p "~/vagrant/archlinux"
   [home]$ cd "${_}"
   [archlinux]$ vagrant init archlinux/archlinux
   ```

1. start the box:

   ```shell
   [archlinux]$ vagrant up

   # re-run provisioning
   [archlinux]$ vagrant up --provision
   ```
  
1. connect to the machine:

   ```shell
   [archlinux]$ vagrant ssh
   ```

## Install autocomplete

```shell
$ vagrant autocomplete install --bash
Autocomplete installed at paths:
- /home/user/.bashrc

$ vagrant autocomplete install --zsh
Autocomplete installed at paths:
- /home/user/.zshrc
```

## Boxes management

```shell
vagrant box add archlinux/archlinux
vagrant box add archlinux/archlinux --provider virtualbox

vagrant box list

vagrant box update
vagrant box update --box generic/gentoo
```

## Customize VM settings

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "archlinux/archlinux"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "3072"
    vb.customize ["modifyvm", :id, "--vram", "64"]
    vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
  end
```

## Use environment variables in the provisioning script

Add the variables as argument of the `config.vm.provision` key:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "shell", env: { "KEYBASE_USERNAME" => ENV['KEYBASE_USERNAME'], "KEYBASE_PAPERKEY" => ENV['KEYBASE_PAPERKEY'] }, inline: <<-SHELL
    pacman -Sy --noconfirm --noprogressbar \
      fzf zsh-completions \
      keybase
    pacman -Scc --noconfirm
    chsh --shell /bin/zsh vagrant
    sudo --user vagrant --preserve-env=KEYBASE_USERNAME,KEYBASE_PAPERKEY keybase oneshot
    sudo --user vagrant --preserve-env=KEYBASE_USERNAME,KEYBASE_PAPERKEY keybase git list
  SHELL
end
```

## Specify the disk size

Install the vagrant-disksize plugin:

```shell
vagrant plugin install vagrant-disksize
```

then set it up:

```ruby
vagrant.configure('2') do |config|
    config.disksize.size = '50GB'
end
```

## Reboot after provision

Add this to the Vagrantfile:

```ruby
config.vm.provision "shell", reboot: true
```

## Further readings

- [getting started]
- [how to set vagrant virtualbox video memory]
- [Pass environment variables to vagrant shell provisioner]
- [Tips & Tricks]
- [Multi-Machine]
- [how to specify the disk size]
- [How do I reboot a Vagrant guest from a provisioner?]

[getting started]: https://learn.hashicorp.com/tutorials/vagrant/getting-started-index
[how do i reboot a vagrant guest from a provisioner?]: https://superuser.com/questions/1338429/how-do-i-reboot-a-vagrant-guest-from-a-provisioner#1579326
[how to set vagrant virtualbox video memory]: https://stackoverflow.com/questions/24231620/how-to-set-vagrant-virtualbox-video-memory#24253435
[how to specify the disk size]: https://stackoverflow.com/questions/49822594/vagrant-how-to-specify-the-disk-size#60185312
[multi-machine]: https://www.vagrantup.com/docs/multi-machine
[pass environment variables to vagrant shell provisioner]: https://stackoverflow.com/questions/19648088/pass-environment-variables-to-vagrant-shell-provisioner#37563822
[tips & tricks]: https://www.vagrantup.com/docs/vagrantfile/tips
