# AMDGPU

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Requirements</summary>

[Supported distributions]

</details>

<details>
  <summary>Installation</summary>
  <details style="margin-left: 1em">
    <summary>OpenSUSE Leap, SUSE Linux Enterprise</summary>

See [Native installation on SLE].

```sh
sudo tee '/etc/zypp/repos.d/amdgpu.repo' <<EOF
[amdgpu]
name=amdgpu
baseurl=https://repo.radeon.com/amdgpu/6.2.2/sle/15.6/main/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://repo.radeon.com/rocm/rocm.gpg.key
EOF

sudo tee --append '/etc/zypp/repos.d/rocm.repo' <<EOF
[ROCm-6.2.2]
name=ROCm6.2.2
baseurl=https://repo.radeon.com/rocm/zyp/6.2.2/main
enabled=1
gpgcheck=1
gpgkey=https://repo.radeon.com/rocm/rocm.gpg.key
EOF

sudo zypper ref
sudo zypper --gpg-auto-import-keys install 'amdgpu-dkms' 'rocm-opencl-runtime'
sudo reboot

dkms status
/opt/rocm-6.2.2/bin/clinfo
```

  </details>
</details>

<details>
  <summary>Uninstallation</summary>
  <details style="margin-left: 1em">
    <summary>OpenSUSE Leap, SUSE Linux Enterprise</summary>

See [Native installation on SLE].

```sh
sudo zypper remove 'rocm-core'
sudo zypper remove --clean-deps 'amdgpu-dkms'
sudo zypper removerepo 'ROCm-6.2.2'
sudo zypper removerepo 'amdgpu'
sudo zypper clean --all
sudo reboot
```

  </details>
</details>

## Further readings

- [ROCm documentation]
- [Docker Hub]

### Sources

- [Supported distributions]
- [Native installation on SLE]
- [Components of ROCm programming models]
- [Running ROCm Docker containers]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[components of rocm programming models]: https://rocm.docs.amd.com/projects/install-on-linux/en/latest/how-to/native-install/package-manager-integration.html#components-of-rocm-programming-models
[docker hub]: https://hub.docker.com/u/rocm
[native installation on sle]: https://rocm.docs.amd.com/projects/install-on-linux/en/latest/how-to/native-install/sles.html
[rocm documentation]: https://rocm.docs.amd.com/en/latest/
[running rocm docker containers]: https://rocm.docs.amd.com/projects/install-on-linux/en/latest/how-to/docker.html
[supported distributions]: https://rocm.docs.amd.com/projects/install-on-linux/en/latest/reference/system-requirements.html#supported-distributions

<!-- Others -->
