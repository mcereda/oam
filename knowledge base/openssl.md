# OpenSSL

1. [TL;DR](#tldr)
1. [Troubleshooting](#troubleshooting)
   1. [Code 20: unable to get local issuer certificate](#code-20-unable-to-get-local-issuer-certificate)
   1. [Code 21: unable to verify the first certificate](#code-21-unable-to-verify-the-first-certificate)
1. [Sources](#sources)

## TL;DR

```sh
# Check a certificate and return information about it.
openssl x509 -in 'certificate.crt' -text -noout

# Check a key and verify its consistency.
openssl rsa -in 'file.key' -check

# Verify a CSR and print the data given in input during creation.
openssl req -in 'request.csr' -text -noout -verify

# Check a PKCS#12 file (.p12 or .pfx).
openssl pkcs12 -info -in 'keyStore.p12'

# Check a MD5 hash of the public key to ensure it matches with the one in a CSR
# or private key.
openssl x509 -noout -modulus -in 'certificate.crt' | openssl md5
openssl rsa -noout -modulus -in 'private.key' | openssl md5
openssl req -noout -modulus -in 'request.csr' | openssl md5

# Check an SSL connection.
# All the certificates (including the intermediate ones) should be displayed.
# CA certificates bundle on Linux: /etc/ssl/certs/ca-certificates.crt.
# '-servername' used to specify a domain for multi-domain servers.
openssl s_client -connect 'fqdn:port' -servername 'host-fqdn' -showcerts
openssl … -CAfile 'ca/certificates/bundle.crt'
openssl … -CApath '/etc/ssl/certs'

# Generate a password-protected self-signed certificate.
openssl req -x509 \
  -sha256 -newkey 'rsa:4096' -keyout 'private.key' \
  -subj '/C=US/ST=Oregon/L=Portland/O=Company Name/OU=Org/CN=www.example.com' \
  -out 'certificate.pem' -days '365'

# Generate a new non-protected signing request.
openssl req -new \
  -config 'domain.conf' \
  -sha256 -newkey 'rsa:2048' -nodes -keyout 'domain.key' \
  -days '365' -out 'domain.req.pem'

# Generate a Certificate Signing Request for an existing private key.
openssl req -new -key 'private.key' -out 'request.csr'

# Generate a Certificate Signing Request from an existing certificate and key.
openssl x509 -x509toreq \
  -in 'certificate.crt' -out 'request.csr' -signkey 'private.key'

# Remove password protection from a key.
openssl rsa -in 'protected.key' -out 'unprotected.key'

# Convert a DER-formatted file (.crt .cer .der) to the PEM format.
openssl x509 -inform 'der' -in 'certificate.cer' -out 'certificate.pem'
openssl x509 -in 'certificate.cer' -out 'certificate.pem' -outform 'PEM'

# Convert a PEM file to the DER format.
openssl x509 -outform 'der' -in 'certificate.pem' -out 'certificate.der'

# Convert a PKCS#12 file (.pfx .p12) with private key and certificates to PEM.
# Add -nocerts to output only the private key.
# Add -nokeys to output only the certificates.
openssl pkcs12 -in 'keyStore.pfx' -out 'keyStore.pem' -nodes

# Convert a PEM certificate file and a private key to PKCS#12 (.pfx .p12).
openssl pkcs12 -export -out 'certificate.pfx' \
  -inkey 'privateKey.key' -in 'certificate.crt' -certfile

# Verify a certificate chain.
# If a certificate is its own issuer, it is assumed to be the root CA.
# This means the root CA needs to be self signed for 'verify' to work.
openssl verify -CAfile 'RootCert.pem' -untrusted 'Intermediate.pem' 'UserCert.pem'

# Create bundles.
# Mind the file order.
cat 'server.crt' 'intermediate1.crt' 'intermediateN.crt' 'rootca.crt'
```

## Troubleshooting

### Code 20: unable to get local issuer certificate

An `openssl s_client -connect` attempt fails with this error message:

```plaintext
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

One or more certificates in the certificate chain is not valid, self-signed or simply was not provided by either the server or the client (if a client certificate is needed).<br />
This could also mean that the root certificate is not in the local database of trusted root certificates, which could have been not given to, or queried by, OpenSSL.

A well configured server sends the entire certificate chain during the handshake, therefore providing all the necessary intermediate certificates; servers for which the connection fails might be providing only the end entity certificate.

OpenSSL is **not** capable of getting missing intermediate certificates on-the-fly, so a `s_client -connect` attempt could fail where a full-fledge browser, able to discover certificates, would succeed on the same URL.

You can:

- either make the server send the entire certificate chain
- or pass the missing certificates to OpenSSL as client-side parameters using the '-CApath' or '-CAfile' options.

### Code 21: unable to verify the first certificate

The certificate chain is broken.<br />
This error is somewhat generic, and a previous error message might be telling more about the problem.

See [code 20](#code-20-unable-to-get-local-issuer-certificate).

## Sources

- [OpenSSL commands to check and verify your SSL certificate, key and CSR]
- [How to generate a self-signed SSL certificate using OpenSSL]
- [The most common OpenSSL commands]
- [OpenSSL unable to verify the first certificate for Experian URL]
- [Verify certificate chain with OpenSSL]

<!-- -->
[how to generate a self-signed ssl certificate using openssl]: https://stackoverflow.com/questions/10175812/how-to-generate-a-self-signed-ssl-certificate-using-openssl#10176685
[openssl commands to check and verify your ssl certificate, key and csr]: https://www.ibm.com/support/pages/openssl-commands-check-and-verify-your-ssl-certificate-key-and-csr
[openssl unable to verify the first certificate for experian url]: https://stackoverflow.com/questions/7587851/openssl-unable-to-verify-the-first-certificate-for-experian-url
[the most common openssl commands]: https://www.sslshopper.com/article-most-common-openssl-commands.html
[verify certificate chain with openssl]: https://www.itsfullofstars.de/2016/02/verify-certificate-chain-with-openssl/
