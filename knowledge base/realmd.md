# Realmd

On-demand system DBus service allowing callers to configure network authentication and domain membership in a standard way.

Realmd discovers information about the domain or realm automatically, and configures [SSSD] or [Winbind] to manage the actual network authentication and user account lookups.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Scan for domains on the network.
realm discover
realm discover 'domain.example.com'

# Add the system to domains.
realm join 'ad.example.com'
realm join --user='admin' --computer-ou='OU=Special' 'domain.example.com'

# List joined domains.
realm list
realm list --all --name-only

# Remove the system from domains.
realm leave 'ad.example.com'


# Enable access to the system for users within configured domains.
realm permit --all
realm permit 'username'
realm permit 'DOMAIN\User2'
realm permit --withdraw 'user@example.com'

# Restrict access to the system for users within configured domain.
realm deny --all
realm deny 'username'
realm deny 'DOMAIN\User2'
```

## Further readings

- [Website]
- [SSSD]
- [Winbind]
- [Integrating Linux systems with Active Directory environments]

<!--
  References
  -->

<!-- Upstream -->
[website]: https://www.freedesktop.org/software/realmd/

<!-- Knowledge base -->
[sssd]: sssd.md

<!-- Others -->
[integrating linux systems with active directory environments]: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/windows_integration_guide/index
[winbind]: https://www.winbind.org/
