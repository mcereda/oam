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

1. Create public **and** private hosted zones with the same name.<br/>
   Split-view DNS will still work if using an external DNS service for the public hosted zone.
1. Associate one or more VPCs with the private hosted zone.<br/>
   Route 53 Resolver will use the private hosted zone to route DNS queries in the associated VPCs.
1. Create records in each hosted zone.

   Records in the _public_ hosted zone will control how **internet** traffic is routed.<br/>
   Records in the _private_ hosted zone will control how traffic is routed **inside the associated VPCs**.

1. Use Route 53 Resolver to perform name resolution of **both** the associated VPC **and** on-premises workloads.

## Further readings

### Sources

- [What is Amazon Route 53?]
- [Split-view DNS]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[split-view dns]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zone-private-considerations.html
[what is amazon route 53?]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html

<!-- Others -->
