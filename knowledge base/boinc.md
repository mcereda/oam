# BOINC

1. [TL;DR](#tldr)
2. [Client management](#client-management)
   1. [Remote management](#remote-management)
3. [Use the GPU for computations](#use-the-gpu-for-computations)
   1. [On OpenSUSE](#on-opensuse)
   2. [Check the GPU is OpenCL-enabled](#check-the-gpu-is-opencl-enabled)
4. [Use VirtualBox for computations](#use-virtualbox-for-computations)
5. [Gotchas](#gotchas)
6. [Further readings](#further-readings)

Files are located in `/var/lib/boinc` by default.  
Some distribution (debian and derivate) use `/etc/boinc-client` for configuration files instead, and create links to the ones in the default location.

## TL;DR

```sh
# Install.
flatpak install 'edu.berkeley.BOINC'
sudo zypper install 'boinc-client' 'boinc-manager'

# Set the GUI RPC communications port.
boinc --gui_rpc_port 30000
```

## Client management

Name            | Type         | Description
--------------- | ------------ | ---
[BOINC Manager] | Graphical    |
[boinccmd]      | Command line |
[boinctui]      | Text         |

Local control RPCs are authenticated using the GUI RPC password. This password is located in the `gui_rpc_auth.cfg` configuration file, as the single first line, with a max length of 255 characters.

A password is **required** from version FIXME, and is automatically generated if the file is not found or it is empty.

### Remote management

All remote RPCs (both status and control) are authenticated using the GUI RPC password.

Quick, dirty solution: use the `--allow_remote_gui_rpc` option when starting the client.<br/>
This will make the BOINC client accept connections from **any** host (subject to password authentication) even if the client's configuration files are set otherwise.

Better solution:

1. add the `<allow_remote_gui_rpc>1</allow_remote_gui_rpc>` **option** to the `cc_config.xml` file in the BOINC data directory
1. restart the service to make the above change effective
1. check port 31416 (or the one configured for use) is reachable from other hosts
1. specify a set of allowed hosts creating the `remote_hosts.cfg` file in the BOINC data directory; its entries must be DNS host names or IP addresses, and must be one per line

   > the _Read config file_ action in BOINC Manager's _Advanced_ menu will also read the `remote_hosts.cfg` file, so a restart of the client is not required to enable changes to the remote host list.

1. check the `gui_rpc_auth.cfg` file in the BOINC data directory to get the password for authentication

## Use the GPU for computations

To use the GPU for projects you may need the proprietary nVidia or AMD drivers. See [AMD Linux drivers] and [Radeon™ Software for Linux® Installation].

```sh
amdgpu-install --usecase=workstation --opencl=rocr
```

The BOINC client seems to need to be added to the `video` group to be able to use the drivers correctly - this is something I still need to check.

```sh
gpasswd -a 'boinc' 'video'
usermod --append --groups 'video' 'boinc'
```

### On OpenSUSE

Install the `amdgpu-install` package from [AMD's Linux drivers][amd linux drivers] page, then execute it.

```sh
# Previous versions of the package (like the one in the official documentation
# at the time of writing) made DKMS fail.
sudo zypper install 'https://repo.radeon.com/amdgpu-install/22.20.3/sle/15.4/amdgpu-install-22.20.50203-1.noarch.rpm'
sudo amdgpu-install
```

At the next restart of the boinc-client, something similar to this line should appear in the client's logs:

```text
Oct 09 23:09:40 hostnameHere boinc[1709]: 09-Oct-2022 23:09:40 [---] OpenCL: AMD/ATI GPU 0: gfx90c:xnack- (driver version 3452.0 (HSA1.1,LC), device ve>
```

### Check the GPU is OpenCL-enabled

Just install and run `clinfo`:

```sh
$ clinfo
Number of platforms     1
  Platform Name         NVIDIA CUDA
  Platform Vendor       NVIDIA Corporation
  Platform Version      OpenCL 1.2 CUDA 10.0.132
…
```

## Use VirtualBox for computations

Install VirtualBox, then add the `boinc` user to the `vboxusers` group:

```sh
usermod --append --groups 'vboxusers' 'boinc'
```

## Gotchas

- it seems to work much better on debian-based distribution
- In order to suspend computing when the computer is in use, the `boinc` user should have access to your X session so that mouse and keyboard input can be communicated to the client:

  ```sh
  xhost +SI:localuser:boinc
  ```

## Further readings

- [BOINC Manager]
- [boinccmd] for the bare CLI utility
- [boinctui] for a TUI manager
- [GUI RPC bind to port 31416 failed: 98]

<!-- internal references -->
[boinccmd]: boinccmd.md

<!-- external references -->
[boinc manager]: https://boinc.berkeley.edu/wiki/BOINC_Manager
[boinctui]: https://www.mankier.com/package/boinc-tui

[amd linux drivers]: https://www.amd.com/en/support/linux-drivers
[radeon™ software for linux® installation]: https://amdgpu-install.readthedocs.io/en/latest/

[gui rpc bind to port 31416 failed: 98]: https://boinc.mundayweb.com/wiki/index.php?title=GUI_RPC_bind_to_port_31416_failed:_98

<!-- FIXME -->

[boinc on arch wiki]: https://wiki.archlinux.org/title/BOINC
[client configuration]: https://boinc.berkeley.edu/wiki/Client_configuration
[controlling boinc remotely]: https://boinc.berkeley.edu/wiki/Controlling_BOINC_remotely
[installing or uninstalling the amdgpu stack]: https://amdgpu-install.readthedocs.io/en/latest/install-installing.html
[linux suspend when computer is in use bug]: https://boinc.berkeley.edu/dev/forum_thread.php?id=14019&postid=101146#101146
