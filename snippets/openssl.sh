#!/usr/bin/env sh

# Generate pseudo-random passwords.
openssl rand 32
openssl rand -base64 18

# Generate certificate signing requests.
# '-nodes' leaves the output files unencrypted.
openssl req -new -out 'gitlab.mine.info.csr' -newkey 'rsa:2048' -keyout 'gitlab.mine.info.new.key'  # also create a key
openssl req -new -out 'gitlab.mine.info.csr' -key 'gitlab.mine.info.existing.key'                   # use existing keys
openssl req -new -out 'gitlab.mine.info.csr.pem' -config 'csr.conf' -days '365' -sha256

# Verify certificate signing requests and print the data given in input on creation.
openssl req -text -noout -verify -in 'gitlab.mine.info.csr'

# Check existing keys and verify their consistency.
openssl rsa -check -in 'gitlab.mine.info.new.key'

# Generate self-signed certificates.
openssl req -x509 -out 'self-signed.certificate.pem' \
	-newkey 'rsa:4096' -keyout 'self-signed.private.key' \
	-subj '/C=US/ST=Oregon/L=Portland/O=Company Name/OU=Org/CN=www.company.com' \
	-days '365' -sha256

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
openssl s_client -connect 'www.google.com:443' -showcerts -servername 'host.fqdn'
openssl s_client -connect 'www.google.com:443' -showcerts -CAfile 'ca/certificates/bundle.crt'
openssl s_client -connect 'www.google.com:443' -showcerts -CApath '/etc/ssl/certs'
