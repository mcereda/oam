# Route 53

AWS DNS service offering.

1. [TL;DR](#tldr)
1. [Split-view](#split-view)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

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

## Split-view

A.K.A _split-horizon_ DNS.

Allows to use the same domain name for both **internal** _and_ **external** uses.

Procedure:

1. Enable DNS resolution and DNS hostnames for any VPC involved.
1. Create public **and** private hosted zones with the same name.<br/>
   Split-view DNS will still work if using an external DNS service for the public hosted zone.
1. Associate one or more VPCs with the **private** hosted zone.<br/>
   Route 53 Resolver will use the private hosted zone to route DNS queries in the associated VPCs.
1. Create records in each hosted zone.

   Records in the _public_ hosted zone will control how **internet** traffic is routed.<br/>
   Records in the _private_ hosted zone will control how traffic is routed **inside the associated VPCs**.

1. Use Route 53 Resolver to perform name resolution of **both** the associated VPC **and** on-premises workloads.

DNS queries for **public** DNS record from VPCs attached to private hosted zone will **not** resolve and will give back
`NXDOMAIN` errors.<br/>
If a record doesn't exist in the private hosted zone, the DNS query **cannot** be forwarded to a public hosted zone.

Resolve public DNS records from VPCs associated with private hosted zones by replicating all public records in the
private hosted zone along with private records.<br/>
Any query coming from a public DNS record will be resolved from the private hosted zone.

## Further readings

- [Documentation]

### Sources

- [Split-view DNS]
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
[split-view dns]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zone-private-considerations.html
[documentation]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/
[how do i use route 53 to access an internal version of my website with the same domain name that is used publicly?]: https://repost.aws/knowledge-center/internal-version-website

<!-- Others -->
[split-view dns using amazon route 53]: https://tutorialsdojo.com/split-view-dns-using-amazon-route-53/
