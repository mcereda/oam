# BOINC

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Client management](#client-management)
   1. [Remote management](#remote-management)
1. [Use the GPU for computations](#use-the-gpu-for-computations)
   1. [AMD drivers](#amd-drivers)
   1. [Intel OpenCL support](#intel-opencl-support)
1. [Use VirtualBox for computations](#use-virtualbox-for-computations)
1. [Ask for tasks for alternative platforms](#ask-for-tasks-for-alternative-platforms)
1. [Gotchas](#gotchas)
1. [Further readings](#further-readings)

## TL;DR

Files are located in `/var/lib/boinc` by default.<br/>
Some distribution (debian and derivate) use `/etc/boinc-client` for configuration files instead, and create links to them in the default location.

The resource share property can be set anywhere from 0 to 1000 for each project, with 0 meaning it will not get any work from that project unless every other project you run is out of work.

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

Resource share is used to help BOINC determine which projects to prioritize. The larger the number, the more it will prioritize work from that project over the other projects. It does not determine anything about how much of your CPU, GPU, etc. are used. If you want to do that, change the relative settings.<br/>
The number for resource share can be set anywhere from 0 to 1000 for each project. Setting a project's resource share to zero means it will not get any work from that project unless every other project you run is out of work.

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

Check the GPU is OpenCL-enabled installing and running `clinfo`:

```sh
$ clinfo
Number of platforms     1
  Platform Name         NVIDIA CUDA
  Platform Vendor       NVIDIA Corporation
  Platform Version      OpenCL 1.2 CUDA 10.0.132
…
```

If the resulting number of platform is `0`, you need to install the proprietary drivers for your card.

The BOINC client seems to need to be added to the `video` group to be able to use the drivers correctly - this is something I still need to check.

```sh
gpasswd -a 'boinc' 'video'
usermod --append --groups 'video' 'boinc'
```

### AMD drivers

See [AMD Linux drivers] and [Radeon™ Software for Linux® Installation] for the AMD drivers.<br/>
If you want to install also the ROCm component, see also the [AMD ROCm™ documentation].

<details><summary>On OpenSUSE</summary>

Install the `amdgpu-install` package from [AMD's Linux drivers][amd linux drivers] page, then execute it.

```sh
# Previous versions of the package (like the one in the official documentation
# at the time of writing) made DKMS fail.
sudo zypper install 'https://repo.radeon.com/amdgpu-install/22.20.3/sle/15.4/amdgpu-install-22.20.50203-1.noarch.rpm'
sudo amdgpu-install --usecase=workstation --opencl=rocr
```

### Intel OpenCL support

```sh
sudo apt install 'intel-opencl-icd' 'ocl-icd-libopencl1'
sudo pacman -Sy 'ocl-icd'
sudo zypper install 'intel-opencl'
```

</details><br/>

At the next restart of the BOINC client, something similar to this line should appear in the event logs:

```txt
Oct 09 23:09:40 hostnameHere boinc[1709]: 09-Oct-2022 23:09:40 [---] OpenCL: AMD/ATI GPU 0: gfx90c:xnack- (driver version 3452.0 (HSA1.1,LC), device ve>
```

## Use VirtualBox for computations

Install VirtualBox, then add the `boinc` user to the `vboxusers` group:

```sh
usermod --append --groups 'vboxusers' 'boinc'
```

## Ask for tasks for alternative platforms

Required, for instance, to compute 32 bit tasks for World Community Grid's tasks on arm64 on Pi 4.<br/>
One line per platform.

See <https://boinc.berkeley.edu/trac/wiki/BoincPlatforms> for the available platforms.

In `cc_config.xml`:

```xml
<cc_config>
  <options>
    <alt_platform>arm-unknown-linux-gnueabihf</alt_platform>
    <alt_platform>arm-unknown-linux-gnueabisf</alt_platform>
  </options>
</cc_config>
```

## Gotchas

- It seems to work much better on debian-based distribution than on others.
- In order to suspend computing when the computer is in use, the `boinc` user should have access to your X session so that mouse and keyboard input can be communicated to the client:

  ```sh
  xhost +SI:localuser:boinc
  ```

## Further readings

- [Website]
- [BOINC Manager]
- [boinccmd] for the bare CLI utility
- [boinctui] for a TUI manager
- [GUI RPC bind to port 31416 failed: 98]
- [AMD ROCm™ documentation]

<!--
  References
  -->

<!-- Upstream -->
[amd linux drivers]: https://www.amd.com/en/support/linux-drivers
[boinc manager]: https://boinc.berkeley.edu/wiki/BOINC_Manager
[client configuration]: https://boinc.berkeley.edu/wiki/Client_configuration
[controlling boinc remotely]: https://boinc.berkeley.edu/wiki/Controlling_BOINC_remotely
[installing or uninstalling the amdgpu stack]: https://amdgpu-install.readthedocs.io/en/latest/install-installing.html
[platforms]: https://boinc.berkeley.edu/trac/wiki/BoincPlatforms
[radeon™ software for linux® installation]: https://amdgpu-install.readthedocs.io/en/latest/
[amd rocm™ documentation]: https://rocm.docs.amd.com/en/latest/
[website]: https://boinc.berkeley.edu/

<!-- In-article sections -->
[boinccmd]: boinccmd.md

<!-- Others -->
[boinc on arch wiki]: https://wiki.archlinux.org/title/BOINC
[boinctui]: https://www.mankier.com/package/boinc-tui
[gui rpc bind to port 31416 failed: 98]: https://boinc.mundayweb.com/wiki/index.php?title=GUI_RPC_bind_to_port_31416_failed:_98
[linux suspend when computer is in use bug]: https://boinc.berkeley.edu/dev/forum_thread.php?id=14019&postid=101146#101146
