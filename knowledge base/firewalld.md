# Firewalld

Firewalld is a dynamically managed firewall with support for network/firewall zones that define the trust level of network connections or interfaces. It has support for IPv4, IPv6, firewall settings, ethernet bridges and IP sets. It also offers separation of runtime and permanent configuration options.

It is the default firewall management tool for:

- RHEL and CentOS 7 and newer
- Fedora 18 and newer
- (Open)SUSE 15 and newer

## TL;DR

```sh
# Show which zone is currently selected as the default.
firewall-cmd --get-default-zone

# List all available zones.
firewall-cmd --get-zones
firewall-cmd --get-zones --permanent

# List the currently active zones only.
firewall-cmd --get-active-zones

# Print the default zone's configuration.
firewall-config --list-all

# Change the default zone.
sudo firewall-cmd --set-default-zone='home'

# Change an interface's zone assignment.
sudo firewall-cmd --zone=home --change-interface='eth0'

# List the available service definitions.
firewall-cmd --get-services

# List the allowed services in a zone.
sudo firewall-cmd --list-services
sudo firewall-cmd --list-services --zone='public'
sudo firewall-cmd --list-services --permanent

# Temporarily allow services.
sudo firewall-cmd --add-service='http'
sudo firewall-cmd --add-service='ssh' --zone='public'

# Permanently allow services.
sudo firewall-cmd --add-service='ssh' --permanent
sudo firewall-cmd --add-service='https' --zone='public' --permanent

# List the open ports in a zone.
sudo firewall-cmd --list-ports
sudo firewall-cmd --list-ports --zone='public'
sudo firewall-cmd --list-ports --permanent

# Temporarily open specific ports.
sudo firewall-cmd --add-port='1978/tcp'
sudo firewall-cmd --add-port='4990-4999/udp' --zone='public'

# Permanently open specific ports.
sudo firewall-cmd --add-port='22/tcp' --permanent
sudo firewall-cmd --add-port='4990-4999/udp' --zone='public' --permanent

# Close an open port.
sudo firewall-cmd --remove-port='1978/tcp'
sudo firewall-cmd --remove-port='1978/tcp' --zone='public'
sudo firewall-cmd --permanent --remove-service='ssh'

# Create a new zone.
sudo firewall-cmd --new-zone='publicweb' --permanent

# Make changes permanent.
sudo firewall-cmd --runtime-to-permanent

# Reload the firewall.
sudo firewall-cmd --reload

# Use the offline version.
# '--permanent' does not work here.
sudo firewall-offline-cmd --add-port='22/tcp' && sudo firewall-cmd --reload
```

## Further readings

- [Website]
- [Documentation]

## Sources

All the references in the [further readings] section, plus the following:

- [Open TCP Port on openSUSE Firewall]
- [How To Set Up a Firewall Using firewalld on CentOS 8]

<!--
  References
  -->

<!-- Upstream -->
[documentation]: https://firewalld.org/documentation/
[website]: https://firewalld.org/

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Others -->
[how to set up a firewall using firewalld on centos 8]: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-using-firewalld-on-centos-8
[open tcp port on opensuse firewall]: https://vazhavandan.blogspot.com/2020/08/open-tcp-port-on-opensuse-firewall.html
