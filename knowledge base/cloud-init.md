# Cloud init

1. [TL;DR](#tldr)
2. [Merge 2 or more files or parts](#merge-2-or-more-files-or-parts)
   1. [In Terraform](#in-terraform)
3. [Further readings](#further-readings)
4. [Sources](#sources)

## TL;DR

```sh
# Get the current status.
cloud-init status
cloud-init status --wait

# Verify that cloud-init received the expected user data.
cloud-init query userdata

# Assert the user data we provided is a valid cloud-config.
# From version 22.2, drops the 'devel' command.
cloud-init devel schema --system --annotate
cloud-init devel schema --config-file '/tmp/user-data'

# Check the raw logs.
cat '/var/log/cloud-init.log'

# Parse and organize cloud-init.log events by stage.
cloud-init analyze show

# Manually run a single cloud-config module onceafter the instance has booted.
sudo cloud-init single --name 'cc_ssh' --frequency 'always'

# Clean up everything so cloud-init can re-run.
sudo cloud-init clean

# Re-run all.
sudo cloud-init init
```

```yaml
#cloud-config

# Sources:
# - https://github.com/trajano/terraform-docker-swarm-aws/blob/master/common.cloud-config

# Add the Docker repository
# https://cloudinit.readthedocs.io/en/latest/topics/modules.html#yum-add-repo
# https://cloudinit.readthedocs.io/en/latest/topics/examples.html#adding-a-yum-repository
#
# Got from the official installation guide at
# https://docs.docker.com/engine/install/rhel/#install-using-the-repository :
#   yum install -y yum-utils && \
#   yum-config-manager --add-repo \
#     https://download.docker.com/linux/rhel/docker-ce.repo && \
#   cat /etc/yum.repos.d/docker-ce.repo
yum_repos:
  docker-ce:
    name: Docker CE Stable - $basearch
    enabled: true
    baseurl: https://download.docker.com/linux/rhel/$releasever/$basearch/stable
    priority: 1
    gpgcheck: true
    gpgkey: https://download.docker.com/linux/rhel/gpg

# Upgrade the instance
# Deactivated as this could take a long time if the image is old
# https://cloudinit.readthedocs.io/en/latest/topics/modules.html#package-update-upgrade-install
# https://cloudinit.readthedocs.io/en/latest/topics/examples.html#run-apt-or-yum-upgrade
package_upgrade: false
package_reboot_if_required: false

# Install required packages
# This will always update the list of packages, regardless of package_update's value.
# https://cloudinit.readthedocs.io/en/latest/topics/modules.html#package-update-upgrade-install
# https://cloudinit.readthedocs.io/en/latest/topics/examples.html#install-arbitrary-packages
#
# docker-ce already depends on docker-ce-cli and containerd.io
packages:
packages:
  - docker-ce
  - jq
  - unzip
```

## Merge 2 or more files or parts

FIXME

See [Merging User-Data sections] for details.

```yaml
#cloud-config
packages:
  - jq
  - unzip

---
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

packages:
  - parallel

---
packages:
  - vim

merge_type: 'list(append)+dict(recurse_array)+str()'
```

### In Terraform

1. create a data resource containing the files in order, one per part:

   ```hcl
   # https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs
   # https://github.com/chrusty/terraform-multipart-userdata/blob/master/example/cloudinit.tf
   data "cloudinit_config" "vm" {
     gzip = true
     base64_encode = true

     part {
       content      = file("files/first.yaml")
       content_type = "text/cloud-config"
     }
     …
     part {
       content      = file("files/n-th.yaml")
       content_type = "text/cloud-config"
       filename     = "n-th.yaml"
       merge_type   = "dict(recurse_array,no_replace)+list(append)"
     }
   }
   ```

1. give its rendered form as input to a vm's userdata attribute or an output resource:

   ```hcl
   resource "azurerm_linux_virtual_machine" "vm" {
     user_data = data.cloudinit_config.vm.rendered
     …
   }

   output "cloudinit_config" {
     value = data.cloudinit_config.vm.rendered
   }
   ```

## Further readings

- [Website]
- [Modules]
- [Examples]
- [Merging User-Data sections]
- [cloud-init multipart encoding issues]
- [Test cloud-init with a multipass container]

## Sources

- [Debugging cloud-init]
- [Tutorial]
- [Cloud-Init configuration merging]

<!-- cloud-init documentation -->
[debugging cloud-init]: https://cloudinit.readthedocs.io/en/latest/topics/debugging.html
[examples]: https://cloudinit.readthedocs.io/en/latest/topics/examples.html
[merging user-data sections]: https://cloudinit.readthedocs.io/en/latest/topics/merging.html
[modules]: https://cloudinit.readthedocs.io/en/latest/topics/modules.html
[tutorial]: https://cloudinit.readthedocs.io/en/latest/topics/tutorial.html
[website]: https://cloud-init.io/

<!-- external references -->
[cloud-init configuration merging]: https://jen20.dev/post/cloudinit-configuration-merging/
[cloud-init multipart encoding issues]: https://github.com/hashicorp/terraform/issues/4794
[test cloud-init with a multipass container]: https://medium.com/open-devops-academy/test-cloud-init-with-a-multipass-containers-e3e3bb740604