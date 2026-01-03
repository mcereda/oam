# Alpine

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

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

# Upgrade to a new release branch.
sed -i'.bak' -e 's/v3.22/v3.23/g' '/etc/apk/repositories' \
&& apk add --upgrade --update-cache 'apk-tools' \
&& apk upgrade --available \
&& reboot

# Update configuration files.
find '/etc' -name "*.apk-new"
diff '/etc/init.d/localmount' '/etc/init.d/localmount.apk-new' \
&& mv -iv '/etc/init.d/localmount.apk-new' '/etc/init.d/localmount'
```

## Further readings

- [Website]
- [Documentation]
- [APK]

### Sources

- [Upgrading Alpine Linux to a new release branch]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[apk]: ../apk.md

<!-- Upstream -->
[Documentation]: https://wiki.alpinelinux.org/wiki/Main_Page
[Upgrading Alpine Linux to a new release branch]: https://wiki.alpinelinux.org/wiki/Upgrading_Alpine_Linux_to_a_new_release_branch
[Website]: https://alpinelinux.org/
