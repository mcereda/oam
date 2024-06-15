# VBoxManage

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Create host-only virtual networks.
VBoxManage hostonlynet add --name='network_name' --enable \
  --netmask='255.255.255.0' --lower-ip=192.168.12.100 --upper-ip=192.168.12.200

# Install extension packs.
wget -q 'https://download.virtualbox.org/virtualbox/6.1.22/Oracle_VM_VirtualBox_Extension_Pack-6.1.22.vbox-extpack' \
  --output-document '/tmp/Oracle_VM_VirtualBox_Extension_Pack-6.1.22.vbox-extpack'
sudo VBoxManage extpack install '/tmp/Oracle_VM_VirtualBox_Extension_Pack-6.1.22.vbox-extpack' --replace \
  --accept-license '33d7284dc4a0ece381196fda3cfe2ed0e1e8e7ed7f27b9a9ebc4ee22e24bd23c'
```

## Further readings

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
<!-- Others -->
