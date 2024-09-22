# Alpine

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Set the correct hostname.
echo 'gitea' > '/etc/hostname'
hostname -F '/etc/hostname'

# Configure DHCP.
cat <<EOF > '/etc/network/interfaces'
auto eth0
iface eth0 inet dhcp
iface eth0 inet6 dhcp
EOF

# Create users.
adduser 'somebody'
adduser -DHS -G 'docker' 'docker'

# Create groups.
addgroup 'new-group'

# Add users to groups.
addgroup 'nobody' 'docker'

# Start services.
rc-update add 'gitea'
rc-service 'gitea' start
```

## Further readings

- [APK]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[apk]: ../apk.md
