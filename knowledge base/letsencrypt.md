# Let's Encrypt

1. [Challenges](#challenges)
   1. [DNS-01 challenge](#dns-01-challenge)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Challenges

### DNS-01 challenge

Requires one to prove one has control over the DNS for one's domain name.<br/>
This also allows one to issue wildcard certificates for the domain name in question.

Proof is achieved by creating a TXT record with a specific value under that domain name.
The procedure is as follows:

1. The ACME client requests Let's Encrypt a token.
1. The client, or anything else capable, creates the TXT record in the DNS at `_acme-challenge.{{ domain name }}`.<br/>
   The value of the record needs to be derived from the token and one's account key.
1. The client requests Let's Encrypt to query the DNS system for the TXT record.
1. If Let's Encrypt finds a match, one can proceed to issue a certificate.

This process kinda only makes sense to leverage the DNS-01 challenge type if one's DNS provider allows for automation.

Let's Encrypt follows the DNS standards when looking up TXT records for DNS-01 validation.<br/>
As such, one can use CNAME or NS records to delegate answering the challenge to other DNS zones, meaning this can be
used to delegate the `_acme-challenge` subdomain to a validation-specific server or zone.

One can have multiple TXT records in place for the same name.<br/>
However, make sure to clean up old TXT records: Let's Encrypt will start rejecting the request if the response size from
the DNS gets too big.

## Further readings

- [Website]
- [ACME]

### Sources

- [Challenge types]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[acme]: acme.placeholder

<!-- Files -->
<!-- Upstream -->
[challenge types]: https://letsencrypt.org/docs/challenge-types/
[website]: https://letsencrypt.org/

<!-- Others -->
