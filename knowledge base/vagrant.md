# Vagrant

## TL;DR

```sh
# Initialize Vagrant.
vagrant init 'archlinux/archlinux'
vagrant init 'debian/testing64' --provider 'virtualbox'

# Start a VM.
vagrant up
vagrant up --provider 'libvirt'

# Connect to a started VM
vagrant ssh

# Print the SSH config snippet to connect to the VM.
vagrant ssh-config

# (re)Provision a VM.
vagrant provision
vagrant up --provision

# Add a Box.
vagrant add 'archlinux/archlinux'
vagrant add 'debian/testing64' --provider 'virtualbox'

# List downloaded Boxes.
vagrant box list

# List outdated Boxes.
vagrant box outdated

# Update a Box.
vagrant box update
vagrant box update --box 'generic/gentoo'

# Remove a Box from the local catalogue.
vagrant box remove 'archlinux/archlinux'

# Destroy a VM.
vagrant destroy
vagrant destroy --force

# Install shells' autocompletion.
vagrant autocomplete install --bash
vagrant autocomplete install --zsh

# Install a Plugin.
vagrant plugin install 'vagrant-disksize'
```

## Usage

> All commands need to be run from the VM's folder.

1. Install Vagrant.
1. Optionally, create a folder to keep all files in order and move into it:

   ```sh
   mkdir 'test-vm'
   cd $_
   ```

1. Create a configuration:

   ```sh
   vagrant init 'archlinux/archlinux'
   ```

1. Start the VM:

   ```sh
   vagrant up

   # Re-provision the VM after startup.
   vagrant up --provision
   ```

1. Connect to the VM:

   ```sh
   vagrant ssh
   ```

### Boxes management

```sh
vagrant box add 'archlinux/archlinux'
vagrant box add 'archlinux/archlinux' --provider virtualbox

vagrant box list

vagrant box update
vagrant box update --box 'generic/gentoo'
```

## Install shells' autocompletion

```sh
$ vagrant autocomplete install --bash
Autocomplete installed at paths:
- /home/user/.bashrc

$ vagrant autocomplete install --zsh
Autocomplete installed at paths:
- /home/user/.zshrc
```

## Customize a Box

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "archlinux/archlinux"

  config.vm.provider "virtualbox" do |vb|
    # Vagrant can call any VBoxManage command prior to booting the machine.
    # Multiple customize directives will be executed in order.
    vb.customize ["modifyvm", :id, "--vram", "64"]
    vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]

    # Some settings have convenience shortcuts.
    vb.name = "xfce4 latest"
    vb.cpus = 2
    vb.memory = "2048"
    vb.default_nic_type = "82543GC"
    vb.gui = true

    # Skip the guest additions check.
    vb.check_guest_additions = false
  end
```

## Use environment variables in the provisioning script

Add the variables as argument of the `config.vm.provision` key:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision :shell do |shell|
    shell.env = {
      "STATIC" => "set-in-config",
      "FORWARDED" => ENV['HOST_VAR'],
      }
    shell.inline = <<-SHELL
      printenv STATIC FORWARDED
      sudo -u vagrant --preserve-env=STATIC,FORWARDED printenv STATIC FORWARDED
    SHELL
  end
end
```

## Specify the disk size

Install the 'vagrant-disksize' plugin:

```sh
vagrant plugin install 'vagrant-disksize'
```

then set it up:

```ruby
vagrant.configure('2') do |config|
    config.disksize.size = '50GB'
end
```

## Reboot after provisioning

Add one of the following to the box's `Vagrantfile`:

```ruby
config.vm.provision "shell", reboot: true

config.vm.provision :shell do |shell|
  shell.privileged = true
  shell.reboot = true
end
```

## Further readings

- [Getting started]
- [How to set vagrant virtualbox video memory]
- [Pass environment variables to vagrant shell provisioner]
- [Tips & tricks]
- [Multi-machine]
- [How to specify the disk size]
- [How do I reboot a Vagrant guest from a provisioner?]
- [Configuring Vagrant virtual machines with .env]

<!-- external references -->
[configuring vagrant virtual machines with .env]: https://www.nickhammond.com/configuring-vagrant-virtual-machines-with-env/
[getting started]: https://learn.hashicorp.com/tutorials/vagrant/getting-started-index
[how do i reboot a vagrant guest from a provisioner?]: https://superuser.com/questions/1338429/how-do-i-reboot-a-vagrant-guest-from-a-provisioner#1579326
[how to set vagrant virtualbox video memory]: https://stackoverflow.com/questions/24231620/how-to-set-vagrant-virtualbox-video-memory#24253435
[how to specify the disk size]: https://stackoverflow.com/questions/49822594/vagrant-how-to-specify-the-disk-size#60185312
[multi-machine]: https://www.vagrantup.com/docs/multi-machine
[pass environment variables to vagrant shell provisioner]: https://stackoverflow.com/questions/19648088/pass-environment-variables-to-vagrant-shell-provisioner#37563822
[tips & tricks]: https://www.vagrantup.com/docs/vagrantfile/tips
