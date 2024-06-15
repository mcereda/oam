# Polkit

Provides an authorization API<br/>.
Those are intended to be used by privileged programs (A.K.A. _mechanisms_) that offer services to unprivileged programs
(A.K.A. _subjects_).

Mechanisms typically treat subjects as **untrusted**.<br/>
For every request from subjects, mechanisms need to determine if the request is authorized or if they should refuse
to service the subject; mechanisms can offload this decision to **the polkit authority** using the polkit APIs.

The system architecture of polkit is comprised of the _Authority_ and an _Authentication Agent_ per user session.<br/>
_Actions_ are defined by applications. Vendors, sites and system administrators can control the authorization policy
using _Authorization Rules_.

The Authentication Agent provided and started by the user's graphical environment

The Authority is implemented as a system daemon (`polkitd`)<br/>
The daemon itself runs as the `polkitd` system user to have little privilege.

Mechanisms, subjects and authentication agents communicate with the authority using the system message bus.

In addition to acting as an authority, polkit allows users to obtain temporary authorization through authenticating
either an administrative user or the owner of the session the client belongs to.<br/>
This is useful for scenarios where mechanisms needs to verify that the operator of the system really is the user or an
administrative user.

## Sources

- Arch Linux's [Wiki page][arch wiki page]
- Polkit's [documentation]
- Polkit's [`man` page][man page]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[documentation]: https://www.freedesktop.org/software/polkit/docs/latest/
[man page]: https://www.freedesktop.org/software/polkit/docs/latest/polkit.8.html

<!-- Others -->
[arch wiki page]: https://wiki.archlinux.org/index.php/Polkit
