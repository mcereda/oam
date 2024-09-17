# Let's Encrypt

1. [Challenges](#challenges)
   1. [DNS-01 challenge](#dns-01-challenge)
1. [Limits](#limits)
   1. [Duplicate certificates](#duplicate-certificates)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Challenges

Refer [Challenge types].

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

## Limits

### Duplicate certificates

Refer [Duplicate certificate limit].

One can request a certificate issuance for **the same _exact set_ of hostnames** up to 5 times per week.<br/>
Once that limit is exceeded, one should receive an error message like the following:

```plaintext
too many certificates (5) already issued for this exact set of domains in the
last 168 hours: example.com login.example.com: see https://letsencrypt.org/docs/duplicate-certificate-limit
```

In this error message example, the _exact set_ is `["example.com", "login.example.com"]`.

Revoking previously issued certificates will **not** reset the duplicate certificate limit.<br/>
Nor that limit can be overridden at the time of writing.

As a workaround, one can request one or more certificates for a **different** _exact set_ of hostnames.<br/>
E.G., requesting a certificate for `[example.com, test.example.com]` will succeed; similarly, requesting separate
certificates for the `[example.com]` and `[login.example.com]` sets will succeed.

## Further readings

- [Website]
- [ACME]

### Sources

- [Challenge types]
- [Duplicate certificate limit]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[acme]: acme.md

<!-- Files -->
<!-- Upstream -->
[challenge types]: https://letsencrypt.org/docs/challenge-types/
[duplicate certificate limit]: https://letsencrypt.org/docs/duplicate-certificate-limit/
[website]: https://letsencrypt.org/

<!-- Others -->
