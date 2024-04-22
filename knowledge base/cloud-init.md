# Cloud init

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Merge 2 or more files or parts](#merge-2-or-more-files-or-parts)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Get the current status.
cloud-init status
cloud-init status --wait

# Verify that cloud-init received the expected user data.
sudo cloud-init query userdata
sudo cat /var/lib/cloud/instance/user-data.txt | gunzip

# Assert the user data we provided is a valid cloud-config.
# From version 22.2, drops the 'devel' command.
sudo cloud-init devel schema --system --annotate
sudo cloud-init devel schema --config-file '/tmp/user-data'

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

<details>
  <summary>In Pulumi</summary>

1. Create a data resource containing the files in order, one per part:

   ```ts
   new cloudinit.Config("example", {
     gzip: false,
     base64Encode: false,
     parts: [
       {
         contentType: "text/cloud-config",
         content: fs.readFileSync("cloud-init/aws.ssm.yaml", "utf8"),
         filename: "cloud-config.ssm.yml",
       },
       {
         contentType: "text/cloud-config",
         content: YAML.stringify({
           number: 3,
           plain: 'string',
           block: 'two\nlines\n'
         }),
         filename: "cloud-config.inline.yml",
         mergeType: "dict(recurse_array,no_replace)+list(append)",
       },
     ],
   });
   ```

1. Give its rendered form as input to a virtual machine's `userdata` attribute, or export it:

   ```ts
   let userData = new cloudinit.Config("userData", { … });
   new aws.ec2.Instance("instance", {
     userData: userData.rendered,
     …
   })
   ```

</details>
<details>
  <summary>In Terraform</summary>

1. Create a data resource containing the files in order, one per part:

   ```hcl
   # https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs
   # https://github.com/chrusty/terraform-multipart-userdata/blob/master/example/cloudinit.tf
   data "cloudinit_config" "vm" {
     gzip = true
     base64_encode = true

     part {
       content      = file("${path.module}/files/cloud-init/first.yaml")
       content_type = "text/cloud-config"
       filename     = "first.yaml"
     }
     …
     part {
       content      = templatefile(
         "${path.module}/templates/cloud-init/n-th.yaml.tftpl",
         {
           key = value
         }
       )
       content_type = "text/cloud-config"
       merge_type   = "dict(recurse_array,no_replace)+list(append)"
       filename     = "n-th.yaml"
     }
   }
   ```

1. Give its rendered form as input to a virtual machine's `userdata` attribute or an output resource:

   ```hcl
   resource "azurerm_linux_virtual_machine" "vm" {
     user_data = data.cloudinit_config.vm.rendered
     …
   }

   output "cloudinit_config" {
     value = data.cloudinit_config.vm.rendered
   }
   ```

</details>

## Further readings

- [Website]
- [Modules]
- [Examples]
- [Merging User-Data sections]
- [cloud-init multipart encoding issues]
- [Test cloud-init with a multipass container]
- [Mime Multi Part Archive] format
- [Docker cloud init example]

### Sources

- [Debugging cloud-init]
- [Tutorial]
- [Cloud-Init configuration merging]
- [Terraform's cloud-init provider]
- [How to test cloud-init locally with Vagrant]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Files -->
[docker cloud init example]: ../examples/cloud-init/docker.yum.yaml

<!-- Upstream -->
[debugging cloud-init]: https://docs.cloud-init.io/en/latest/howto/debugging.html
[examples]: https://docs.cloud-init.io/en/latest/reference/examples.html
[merging user-data sections]: https://docs.cloud-init.io/en/latest/reference/merging.html
[modules]: https://cloudinit.readthedocs.io/en/latest/topics/modules.html
[mime multi part archive]: https://cloudinit.readthedocs.io/en/latest/topics/format.html#mime-multi-part-archive
[tutorial]: https://docs.cloud-init.io/en/latest/tutorial/
[website]: https://cloud-init.io/

<!-- Others -->
[cloud-init configuration merging]: https://jen20.dev/post/cloudinit-configuration-merging/
[cloud-init multipart encoding issues]: https://github.com/hashicorp/terraform/issues/4794
[how to test cloud-init locally with vagrant]: https://www.grzegorowski.com/how-to-test-cloud-init-locally-with-vagrant
[terraform's cloud-init provider]: https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/cloudinit_config
[test cloud-init with a multipass container]: https://medium.com/open-devops-academy/test-cloud-init-with-a-multipass-containers-e3e3bb740604
