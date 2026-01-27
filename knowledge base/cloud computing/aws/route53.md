# Route 53

AWS DNS service offering.

1. [TL;DR](#tldr)
1. [Split-view DNS](#split-view-dns)
1. [Hosted zones have overlapping namespaces](#hosted-zones-have-overlapping-namespaces)
1. [Delegate responsibility for subdomains](#delegate-responsibility-for-subdomains)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Amazon-provided DNS servers for a VPC use the IP address at the base of that VPC network range plus 2.<br/>
E.g., if the CIDR range for a VPC is `10.0.0.0/16`, the IP address of the DNS server is `10.0.0.2`.<br/>
E.g., if the CIDR range for a VPC is `172.31.0.0/16`, the IP address of the DNS server is `172.31.0.2`.

<!-- Uncomment if used
<details>
  <summary>Setup</summary>

```sh
```

</details>
-->

<details>
  <summary>Usage</summary>

```sh
# List hosted zones.
aws route53 list-hosted-zones
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Split-view DNS

A.K.A _split-horizon_ DNS.

Allows resolving the **same** domain name to both private **and** public records.<br/>
The resolver will serve the _private_ record when the request comes from **inside** an associated VPC, and the _public_
one for requests coming from **outside** of them.

Procedure:

1. Enable DNS resolution and DNS hostnames for any VPC involved.
1. Create both public **and** private hosted zones with the same namespaces (e.g., `example.org`).<br/>
   Split-view DNS are supposed to still work when using an external DNS service for the public hosted zone.
1. Associate one or more involved VPCs with the **private** hosted zone.<br/>
   Route 53's Resolver will use the private hosted zone to resolve DNS queries originating from those VPCs.
1. Create records in **each** hosted zone.

   Records in the _private_ hosted zone will resolve requests that originate from **inside** the associated VPCs.<br/>
   Records in the _public_ hosted zone will resolve requests that originate from **outside** the associated VPCs.

1. Use Route 53's Resolver to perform name resolution of **both** the associated VPC **and** on-premises workloads.

Queries for DNS records that do **not** exist in the _private_ hosted zone will **not** be forwarded to the _public_ one
using the same namespace.<br/>
As such, queries for **public** DNS record (those that do **not** have a private record for
the same name) coming from inside VPCs associated to the **private** hosted zone will **not** be able to resolve, and
will give back `NXDOMAIN` errors instead.

Resolve public DNS records from VPCs associated with private hosted zones by **replicating** all those public records in
the private hosted zone, along with private records.<br/>
Any query coming from a public DNS record **will** be resolved from the private hosted zone using the same namespace.

## Hosted zones have overlapping namespaces

When hosted zones (private or public) have overlapping namespaces, e.g. `example.org` and `accounting.example.org`,
VPC Resolver checks the one that has the **most specific** match, and will **ignore** the rest.

If any VPC Resolver rule exists for the same namespace of a hosted zone, rules **will** take precedence.

<details>
  <summary>Example: resolution from an EC2 instance</summary>

Consider an EC2 instance in a VPC associated with a private hosted zone.<br/>
VPC Resolver handles DNS queries from that instance as follows:

1. VPC Resolver evaluates whether the name of the private hosted zone matches the domain name in the request.<br/>
   A match is defined as one of the following (either-or):

   - The requested domain name is an identical match.
   - The namespace of the private hosted zone is a **parent** of the domain name in the request.<br/>
     E.g., `vancouver.accounting.example.org` would match `accounting.example.org` and `example.org`.

1. If no private hosted zone matches, VPC Resolver forwards the request to a public DNS resolver and the request is
   treated as a regular DNS query.
1. If a private hosted zone name matches the domain name in the request, that hosted zone is searched for a record
   matching the request's domain name and DNS type, e.g. an `A` record for `accounting.example.org`.

   > [!important]
   > If the private hosted zone does match, but contains no record matching the request's domain name and type, VPC
   > Resolver will **not** forward the request to a public DNS resolver.<br/>
   > Instead, it will return a `NXDOMAIN` (non-existent domain) error to the client.

</details>

## Delegate responsibility for subdomains

Create NS records in a private hosted zone to delegate responsibility for a subdomain.

Refer [Resolver delegation rules tutorial].

## Further readings

- [Documentation]

### Sources

- [Considerations when working with a private hosted zone]
- [Split-view DNS using Amazon Route 53]
- [How do I use Route 53 to access an internal version of my website with the same domain name that is used publicly?]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[Considerations when working with a private hosted zone]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zone-private-considerations.html
[Documentation]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/
[How do I use Route 53 to access an internal version of my website with the same domain name that is used publicly?]: https://repost.aws/knowledge-center/internal-version-website
[Resolver delegation rules tutorial]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/outbound-delegation-tutorial.html

<!-- Others -->
[Split-view DNS using Amazon Route 53]: https://tutorialsdojo.com/split-view-dns-using-amazon-route-53/
