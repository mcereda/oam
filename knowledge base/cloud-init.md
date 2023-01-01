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
cat '/var/log/cloud-init-output.log'

# Parse and organize the events in the log file by stage.
cloud-init analyze show

# Manually run a single cloud-config module once after the instance has booted.
sudo cloud-init single --name 'cc_ssh' --frequency 'always'

# Clean up everything so `cloud-init` can run again.
sudo cloud-init clean

# Re-run everything.
sudo cloud-init init

# Check the user scripts.
ls '/var/lib/cloud/instance/scripts'
```

```yaml
#cloud-config

# Add the Docker repository
yum_repos:
  docker-ce:
    name: Docker CE Stable - $basearch
    enabled: true
    baseurl: https://download.docker.com/linux/rhel/$releasever/$basearch/stable
    priority: 1
    gpgcheck: true
    gpgkey: https://download.docker.com/linux/rhel/gpg

# Upgrade the instance
package_upgrade: true
package_reboot_if_required: true

# Install required packages
# docker-ce already depends on docker-ce-cli and containerd.io
packages:
  - docker-ce
  - jq
  - unzip

# Enable and start the service after installation
runcmd:
  - systemctl daemon-reload
  - systemctl enable --now docker.service
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
- [Mime Multi Part Archive] format
- [Docker cloud init example]

## Sources

- [Debugging cloud-init]
- [Tutorial]
- [Cloud-Init configuration merging]
- [Terraform's cloud-init provider]
- [How to test cloud-init locally with Vagrant]

<!-- cloud-init documentation -->
[debugging cloud-init]: https://cloudinit.readthedocs.io/en/latest/topics/debugging.html
[examples]: https://cloudinit.readthedocs.io/en/latest/topics/examples.html
[merging user-data sections]: https://cloudinit.readthedocs.io/en/latest/topics/merging.html
[modules]: https://cloudinit.readthedocs.io/en/latest/topics/modules.html
[mime multi part archive]: https://cloudinit.readthedocs.io/en/latest/topics/format.html#mime-multi-part-archive
[tutorial]: https://cloudinit.readthedocs.io/en/latest/topics/tutorial.html
[website]: https://cloud-init.io/

<!-- internal references -->
[docker cloud init example]: ../cloud-init/docker.yaml

<!-- external references -->
[cloud-init configuration merging]: https://jen20.dev/post/cloudinit-configuration-merging/
[cloud-init multipart encoding issues]: https://github.com/hashicorp/terraform/issues/4794
[how to test cloud-init locally with vagrant]: https://www.grzegorowski.com/how-to-test-cloud-init-locally-with-vagrant
[terraform's cloud-init provider]: https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/cloudinit_config
[test cloud-init with a multipass container]: https://medium.com/open-devops-academy/test-cloud-init-with-a-multipass-containers-e3e3bb740604
