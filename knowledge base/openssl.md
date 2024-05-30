# OpenSSL

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Create a self signed certificate](#create-a-self-signed-certificate)
1. [Display the contents of a SSL certificate](#display-the-contents-of-a-ssl-certificate)
1. [Troubleshooting](#troubleshooting)
   1. [Code 20: unable to get local issuer certificate](#code-20-unable-to-get-local-issuer-certificate)
   1. [Code 21: unable to verify the first certificate](#code-21-unable-to-verify-the-first-certificate)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Generate pseudo-random passwords.
openssl rand 32
openssl rand -base64 18

# Generate certificate signing requests.
# '-nodes' leaves the output files unencrypted.
openssl req -new -out 'request.csr' \
  -newkey 'rsa:2048' -keyout 'private.key'
openssl req -new -out 'request.csr' -key 'private.key'
openssl req -new -out 'domain.req.pem' … \
  -config 'domain.conf' -days '365' -sha256

# Generate certificate signing requests from existing certificates and keys.
openssl x509 -x509toreq -out 'request.csr' \
  -in 'certificate.crt' -signkey 'private.key'

# Generate self-signed certificates.
openssl req -x509 -out 'certificate.pem' \
  -newkey 'rsa:4096' -keyout 'private.key' \
  -subj '/C=US/ST=Oregon/L=Portland/O=Company Name/OU=Org/CN=www.company.com' \
  -days '365' -sha256
openssl req -x509 -out 'certificate.pem' … -key 'private.key'


# Check PKCS#12 file (.p12 or .pfx).
openssl pkcs12 -info -in 'keyStore.p12'

# Verify certificate signing requests and print the data given in input
# during their creation.
openssl req -text -noout -verify -in 'request.csr'

# Check existing keys and verify their consistency.
openssl rsa -check -in 'file.key'

# Check certificates or keys and return information about them.
openssl x509 -text -noout -in 'certificate.crt'
openssl rsa -text -noout -in 'private.key'

# Verify certificate chains.
# If a certificate is its own issuer, it is assumed to be the root CA.
# This means the root CA needs to be self signed for 'verify' to work.
openssl verify -CAfile 'RootCert.pem' -untrusted 'Intermediate.pem' 'UserCert.pem'


# Check SSL connections.
# All the certificates (including the intermediate ones) should be displayed.
# CA certificates bundle on Linux: '/etc/ssl/certs/ca-certificates.crt'.
# '-servername' is used to specify a domain for multi-domain servers.
openssl s_client -connect 'www.google.com:443' -showcerts
openssl s_client … -servername 'host.fqdn'
openssl s_client … -CAfile 'ca/certificates/bundle.crt'
openssl s_client … -CApath '/etc/ssl/certs'


# Print out the MD5 hash of public keys.
openssl req -noout -modulus -in 'request.csr' | openssl md5
openssl rsa -noout -modulus -in 'private.key' | openssl md5
openssl x509 -noout -modulus -in 'certificate.crt' | openssl md5


# Remove password protection from keys.
openssl rsa -in 'protected.key' -out 'unprotected.key'

# Protect keys with passwords.
openssl rsa -aes192 -in 'unprotected.key' -out 'protected.key'


# Print the public key corresponding to private ones.
openssl rsa -in private.pem -pubout
openssl rsa -in private.pem -pubout -out public.pem


# Convert DER-formatted files (.crt .cer .der) to the PEM format.
openssl x509 -inform 'der' -in 'certificate.cer' -out 'certificate.pem'
openssl x509 -in 'certificate.cer' -out 'certificate.pem' -outform 'pem'

# Convert PEM files to the DER format.
openssl x509 -outform 'der' -in 'certificate.pem' -out 'certificate.der'

# Convert PKCS#12 files (.pfx .p12) with private key and certificates to PEM.
# '-nocerts' outputs only the private key.
# '-nokeys' outputs only the certificates.
# '-nodes' leaves the output files unencrypted.
openssl pkcs12 -in 'keyStore.pfx' -out 'keyStore.pem' -nodes

# Convert PEM certificates and private keys to PKCS#12 (.pfx .p12).
openssl pkcs12 -export -out 'certificate.pfx' \
  -inkey 'privateKey.key' -in 'certificate.crt' \
  -certfile 'cacert.crt'


# Create bundles.
# Mind the file order.
cat 'server.crt' 'intermediate1.crt' 'intermediateN.crt' 'rootca.crt'
```

## Create a self signed certificate

```sh
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
```

To make it **not** ask for a password, add the `-nodes` option.

To avoid answering the questions (for automation), add
`-subj "/C=US/ST=Oregon/L=Portland/O=Company Name/OU=Org/CN=www.example.com"`:

```sh
$ openssl req -x509 -out 'cert.pem' \
  -newkey 'rsa:4096' -keyout 'key.pem' -days '365' -nodes -subj "/C=NL/ST=Nederlands/L=Amsterdam/O=Mek Net/OU=Org/CN=mek.info"
Generating a 4096 bit RSA private key
..............................................................................................................................................................................................................................++
...........................................................................................................................................................................++
writing new private key to 'key.pem'
-----

$ ls
key.pem                       cert.pem
```

## Display the contents of a SSL certificate

```sh
# if PEM formatted
$ openssl x509 -in cert.pem -text

# if DER formatted
$ openssl x509 -in cert.der -inform der -text
```

```txt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            bc:ac:32:b7:cd:42:3f:e3:05:48:36:ed:84:fc:56:b8
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=bed8ecc9-ae31-40b9-bb27-448ec91dd6f4
…
Rq4HD9Ap8Ew1r9ttTeECig==
-----END CERTIFICATE-----
```

## Troubleshooting

### Code 20: unable to get local issuer certificate

An `openssl s_client -connect` attempt fails with this error message:

```txt
CONNECTED(00000003)
depth=0 C = US, CN = server.fqdn
verify error:num=20:unable to get local issuer certificate
verify return:1
depth=0 C = US, CN = server.fqdn
verify error:num=21:unable to verify the first certificate
verify return:1
---
…
SSL-Session:
    …
    Verify return code: 21 (unable to verify the first certificate)
---
closed
```

See also [OpenSSL unable to verify the first certificate for Experian URL] and [Verify certificate chain with OpenSSL].

One or more certificates in the certificate chain is not valid, self-signed or simply was not provided by either the
server or the client (if a client certificate is needed).<br />
This could also mean that the root certificate is not in the local database of trusted root certificates, which could
have been not given to, or queried by, OpenSSL.

A well configured server sends the entire certificate chain during the handshake, therefore providing all the necessary
intermediate certificates; servers for which the connection fails might be providing only the end entity certificate.

OpenSSL is **not** capable of getting missing intermediate certificates on-the-fly, so a `s_client -connect` attempt
could fail where a full-fledge browser, able to discover certificates, would succeed on the same URL.

You can:

- Either make the server send the entire certificate chain, or
- Pass the missing certificates to OpenSSL as client-side parameters using the '-CApath' or '-CAfile' options.

### Code 21: unable to verify the first certificate

The certificate chain is broken.<br />
This error is somewhat generic, and a previous error message might be telling more about the problem.

See [code 20](#code-20-unable-to-get-local-issuer-certificate).

## Further readings

- [OpenSSL commands to check and verify your SSL certificate, key and CSR]
- [The most common OpenSSL commands]
- [Create a self signed certificate]
- [Display the contents of a SSL certificate]
- [Check SSL certificate chain with OpenSSL examples]

### Sources

- [How to generate a self-signed SSL certificate using OpenSSL]
- [OpenSSL unable to verify the first certificate for Experian URL]
- [Verify certificate chain with OpenSSL]
- [How to put domain correctly in CSR?]
- [OpenSSL command cheatsheet]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Others -->
[check ssl certificate chain with openssl examples]: https://www.howtouselinux.com/post/certificate-chain
[create a self signed certificate]: https://stackoverflow.com/questions/10175812/how-to-create-a-self-signed-certificate-with-openssl#10176685
[display the contents of a ssl certificate]: https://support.qacafe.com/knowledge-base/how-do-i-display-the-contents-of-a-ssl-certificate/
[how to generate a self-signed ssl certificate using openssl]: https://stackoverflow.com/questions/10175812/how-to-generate-a-self-signed-ssl-certificate-using-openssl#10176685
[how to put domain correctly in csr?]: https://www.namecheap.com/support/knowledgebase/article.aspx/9641/2290/how-to-put-domain-correctly-in-csr/
[openssl command cheatsheet]: https://www.freecodecamp.org/news/openssl-command-cheatsheet-b441be1e8c4a
[openssl commands to check and verify your ssl certificate, key and csr]: https://www.ibm.com/support/pages/openssl-commands-check-and-verify-your-ssl-certificate-key-and-csr
[openssl unable to verify the first certificate for experian url]: https://stackoverflow.com/questions/7587851/openssl-unable-to-verify-the-first-certificate-for-experian-url
[the most common openssl commands]: https://www.sslshopper.com/article-most-common-openssl-commands.html
[verify certificate chain with openssl]: https://www.itsfullofstars.de/2016/02/verify-certificate-chain-with-openssl/
