# SSL certificate

Verify a server's identity and owner, and encrypt web traffic using SSL/TLS.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

For an SSL certificate to be valid, its owner needs to obtain it from a certificate authority (CA).<br/>
CAs are trusted third party organization that generate and give out SSL certificates. They digitally sign the
certificate with their own private key, allowing client devices to verify the full chain.

Once a certificate is issued, it and its private key need to be available to the website's origin server.<br/>
Once it is, the server will be able to use HTTPS and encrypt traffic.

Certificates include:

- The main domain name that the certificate file was issued for.
- Which person, organization, or device the certificate was issued to.
- Which certificate authority issued it.
- The certificate authority's digital signature.
- Associated subdomains and alternate names.
- Issue date of the certificate.
- Expiration date of the certificate.
- The public key.

Anyone can create their own SSL certificate by generating a public-private key pair and including the aforementioned
information.<br/>
Such _self-signed_ certificates use the private key for their own digital signature, instead of that from a CA. No
outside authority verifies that the origin server is who it claims to be.<br/>
Browsers don't consider self-signed certificates trustworthy; they can mark servers using one as _insecure_ by default
and may terminate the connection altogether to block the server from loading.

<!-- Uncomment if used
<details>
  <summary>Setup</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Let's Encrypt], a Certificate Authority that provides free TLS certificates.
- [OpenSSL]

### Sources

- [What is an SSL certificate?]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Let's Encrypt]: letsencrypt.md
[OpenSSL]: openssl.md

<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[What is an SSL certificate?]: https://www.cloudflare.com/learning/ssl/what-is-an-ssl-certificate/
