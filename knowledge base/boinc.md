# BOINC

1. [TL;DR](#tldr)
2. [Client management](#client-management)
3. [Use the GPU for computation](#use-the-gpu-for-computation)
   1. [On OpenSUSE](#on-opensuse)
4. [Further readings](#further-readings)

## TL;DR

```sh
# Install.
flatpak install 'edu.berkeley.BOINC'
sudo zypper install 'boinc-client' 'boinc-manager'
```

## Client management

Name            | Type         | Description
--------------- | ------------ | ---
[BOINC Manager] | Graphical    |
[boinccmd]      | Command line |
[boinctui]      | Text         |

## Use the GPU for computation

Also see [AMD Linux drivers] and [Radeon™ Software for Linux® Installation].

The BOINC client seems to need to be added to the `video` group to be able to use the drivers correctly - this is something I stiil need to check.

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

## Further readings

- [BOINC Manager]
- [boinccmd]
- [boinctui]

<!-- internal references -->
[boinccmd]: boinccmd.md

<!-- external references -->
[boinc manager]: https://boinc.berkeley.edu/wiki/BOINC_Manager
[boinctui]: https://www.mankier.com/package/boinc-tui

[amd linux drivers]: https://www.amd.com/en/support/linux-drivers
[radeon™ software for linux® installation]: https://amdgpu-install.readthedocs.io/en/latest/
