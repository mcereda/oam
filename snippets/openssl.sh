#!/usr/bin/env sh


##
# Passwords
##

# Generate pseudo-random passwords
openssl rand '32'
openssl rand -base64 '18' > 'key.bin'


##
# Private keys
##

# Generate RSA keys
openssl genrsa -out 'rsa4096.key' '4096'
openssl genrsa -out 'rsa8192.key' '8192'

# Generate RSA keys encrypted with passphrases based on AES CBC 256
openssl genrsa -aes256 -out 'rsa4096.withPassphrase.key' '4096'

# Generate ECDSA keys
# Supported curves: prime256v1, secp384r1, secp521r1, others
openssl ecparam -genkey -name 'secp521r1' | openssl ec -out 'ec521.key'

# List available EC curves
openssl ecparam -list_curves

# Print out key information
openssl rsa -in 'rsa.key' -pubout          # public key
openssl rsa -in 'rsa.key' -noout -modulus  # modulus

# Print out key information
# Textual representation of components
openssl rsa -in 'rsa.key' -text -noout
openssl ec -in 'ec.key' -text -noout

# Check keys and verify their consistency.
openssl rsa -check -in 'private.key'

# Remove passphrases from keys
openssl rsa -in 'withPassphrase.key' -out 'plain.key'

# Encrypt existing keys with passphrases
openssl rsa -des3 -in 'plain.key' -out 'withPassphrase.key'

# Generate Diffie-Hellman params with given lengths (in bits)
openssl dhparam -out 'dhparams.pem' '2048'


##
# Certificate Signing Requests (CSR)
# ----------------------------------
# Digests must be names of supported has functions (md5, sha1, sha224, sha256, sha384, sha512, …)
##

# Create CSRs from existing private keys
openssl req -new -key 'private.key' -out 'request.csr'
openssl req -new -key 'private.key' -out 'request.csr' -sha512

# Create CSRs *and* their private keys
# '-nodes' leaves the output file unencrypted
openssl req -nodes -newkey 'rsa:4096' -keyout 'private.key' -out 'request.csr'
openssl req -new -newkey 'rsa:2048' -keyout 'private.key' -out 'request.csr'

# Provide CSR subject information non-interactively
# => on the CLI rather than through interactive prompt
openssl req -nodes -newkey 'rsa:8192' -keyout 'private.key' -out 'request.csr' \
	-subj "/C=UA/ST=Kharkov/L=Kharkov/O=Super Secure Company/OU=IT Department/CN=example.com"

# Create CSRs from existing certificates and private keys
openssl x509 -x509toreq -in 'certificate.pem' -out 'request.csr' -signkey 'private.key'

# Generate CSRs for multi-domain SAN certificates by supplying OpenSSL config files
openssl req -new -key 'private.key' -out 'request.csr' -config 'request.conf'
openssl req -new -out 'certificate.pem' -config 'csr.conf' -days '365' -sha256
# with 'request.conf' being:
#   [req]prompt=nodefault_md = sha256distinguished_name = dnreq_extensions = req_ext
#   [dn]CN=example.com
#   [req_ext]subjectAltName=@alt_names
#   [alt_names]DNS.1=example.comDNS.2=www.example.comDNS.3=ftp.example.com

# Verify CSR signatures
openssl req -in 'request.csr' -verify
openssl req -in 'request.csr' -verify -text -noout  # prints the data given in input during creation


##
# X.509 certificates
##

# Create self-signed certificates with their new private key from scratch
openssl req -nodes -newkey 'rsa:2048' -keyout 'private.key' -out 'certificate.crt' -x509 -days '365'
openssl req -newkey 'rsa:4096' -keyout 'private.key' -out 'certificate.pem' -x509 -days '365' -sha256 \
	-subj '/C=US/ST=Oregon/L=Portland/O=Company Name/OU=Org/CN=www.company.com'

# Create self-signed certificates using existing CSRs and private keys
openssl x509 -req -in 'request.csr' -signkey 'private.key' -out 'certificate.crt' -days '365'

# Sign child certificates using one's own CA certificates and their private keys
# Very naive example of how to issue new certificates should one be a CA company
openssl x509 -req -in 'child.csr' -days '365' -CA 'ca.crt' -CAkey 'ca.key' -set_serial '01' -out 'child.crt'

# Print out certificate information
openssl x509 -in 'certificate.crt' -text -noout                 # textual representation of components
openssl x509 -in 'certificate.crt' -fingerprint -sha256 -noout  # fingerprint as sha256 digest
openssl x509 -in 'certificate.crt' -fingerprint -md5 -noout     # fingerprint as md5 digest

# Verify certificate chains
# If a certificate is its own issuer, it is assumed to be the root CA (needs to be self signed)
openssl verify 'certificate.crt'  # root and *all* intemediate certificates need to be trusted by the local machine
openssl verify -untrusted 'intermediate-ca-chain.pem' 'certificate.crt'  # the root certificate needs to be trusted by the local machine
openssl verify -purpose 'sslserver' -untrusted 'chain.pem' 'fullchain.pem'
openssl verify -CAfile 'root.crt' -untrusted 'intermediate-ca-chain.pem' 'child.crt'

# Verify certificates served by remote servers cover the given hostnames
# Checks mutlidomain certificates properly cover all the hostnames
# All the certificates (including the intermediate ones) should be displayed
# CA certificates bundle on Linux: '/etc/ssl/certs/ca-certificates.crt'
# '-servername' is used to specify a domain for multi-domain servers
openssl s_client -verify_hostname 'www.example.com' -connect 'example.com:443'
openssl s_client -connect 'www.google.com:443' -showcerts -CAfile 'ca/certificates/bundle.crt'
openssl s_client -connect 'www.google.com:443' -showcerts -CApath '/etc/ssl/certs'

# Convert certificate between DER and PEM formats
openssl x509 -in 'certificate.pem' -outform 'der' -out 'certificate.der'
openssl x509 -in 'certificate.der' -inform 'der' -out 'certificate.pem'

# Combine certificates into PKCS7 (P7B) files
openssl crl2pkcs7 -nocrl -certfile 'child.crt' -certfile 'ca.crt' -out 'example.p7b'

# Convert from PKCS7 to PEM
# If PKCS7 files have multiple certificates, the reulting PEM files will contain all of the items from the PKCS7 files.
openssl pkcs7 -in 'example.p7b' -print_certs -out 'example.crt'

# Combine PEM certificate files and private keys to PKCS#12 (.pfx .p12)
# One can add chains of certificates to PKCS12 files.
openssl pkcs12 -export -out 'certificate.pfx' -inkey 'private.key.pem' -in 'certificate.pem' -certfile 'ca-chain.pem'

# Convert PKCS#12 files (.pfx .p12) containing private keys and certificates to PEM
openssl pkcs12 -in 'keystore.pfx' -out 'keystore.pem' -nodes


##
# TLS client
# --------------------------------------
##

# Tests connections to remote servers
openssl s_client -connect 'www.google.com:443' < '/dev/null'
openssl s_client -host 'www.google.com' -port '443' < '/dev/null'  # deprecated in favour of '-connect'

# Show the full certificate chains
openssl s_client … -showcerts

# Extract certificates
openssl s_client … 2>&1 | sed -n '/-----BEGIN/,/-----END/p' > 'certificate.pem'

# Override SNI (Server Name Indication) extension with other server names
# Allows testing multiple secure sites hosted by same IP address
openssl s_client … -servername 'host.fqdn'
openssl s_client -host 'localhost' -port '8443' -servername 'testcert.com' < '/dev/null'

# Test TLS connections by forcibly using specific cipher suites
# Checks if servers can properly talk via different configured cipher suites
openssl s_client … -cipher 'ECDHE-RSA-AES128-GCM-SHA256' 2>&1

# Measure SSL connection time without and with session reuse
openssl s_time … -new
openssl s_time … -reuse
# Roughly examine TCP and SSL handshake times using `curl`
curl -kso '/dev/null' -w "tcp:%{time_connect}, ssldone:%{time_appconnect}\n" 'https://example.com'


##
# Others
##

# Verify private keys match certificates and CSRs
openssl rsa -noout -modulus -in 'private.key' | openssl sha256
openssl req -noout -modulus -in 'request.csr' | openssl sha256
openssl x509 -noout -modulus -in 'certificate.crt' | openssl sha256

# Check certificates or keys and return information about them
openssl x509 -text -noout -in 'certificate.crt'
openssl rsa -text -noout -in 'private.key'

# Calculate digests
openssl dgst -md5 < 'input.file'
cat 'input.file' | openssl md5
openssl dgst -sha1 < 'input.file'
cat 'input.file' | openssl sha1
openssl dgst -sha512 < 'input.file'
cat 'input.file' | openssl sha512

# Base64 encoding and decoding
echo 'plaintext' | openssl base64
echo 'cGxhaW50ZXh0Cg==' | openssl base64 -d
cat '/dev/urandom' | head -c 50 | openssl base64 | openssl base64 -d

# Measure speed of security algorithms
openssl speed 'rsa2048'
openssl speed 'ecdsap256'

# List available TLS cipher suites
openssl ciphers -v

# Enumerate individual cipher suites
# Described by a short-hand OpenSSL cipher list string
# Useful to test 'ssl_ciphers' string
openssl ciphers -v 'EECDH+ECDSA+AESGCM:EECDH+aRSA+SHA256:EECDH:DHE+AESGCM:DHE:!RSA!aNULL:!eNULL:!LOW:!RC4'

# Encrypt files
openssl enc -aes-256-cbc -salt -pbkdf2 -in 'FILE_TO_ENCRYPT' -out 'FILE_TO_ENCRYPT.enc' -pass 'file:./key.bin'
openssl pkeyutl -pubin -encrypt -in 'key.bin' -out 'enc.key.bin' \
	-inkey 'RSAPublic.bin' -keyform 'DER' -pkeyopt 'rsa_padding_mode:oaep' -pkeyopt 'rsa_oaep_md:sha256'

# Decrypt files
openssl enc -d -aes-256-cbc -pbkdf2 -in 'FILE_TO_DECRYPT.enc' -out 'DECRYPTED_FILE' -pass 'file:./decryptedKey.bin'


##
# Check certificate revocation status from OCSP responders
# --------------------------------------
# Multi-step process:
# 1. Retrieve the certificate from a remote server
# 2. Obtain the intermediate CA certificate chain
#    Use '-showcerts' to show the full certificate chain, and manually save all intermediate certificates to 'chain.pem' files
# 3. Read OCSP endpoint URI from the certificate
# 4. Request a remote OCSP responder for certificate revocation status
##

openssl s_client -connect 'example.com:443' 2>&1 < '/dev/null' | sed -n '/-----BEGIN/,/-----END/p' > 'cert.pem'
openssl s_client -showcerts -host 'example.com' -port '443' < '/dev/null'
openssl x509 -in 'cert.pem' -noout -ocsp_uri
openssl ocsp -header "Host" "ocsp.stg-int-x1.letsencrypt.org" \
	-issuer 'chain.pem' -VAfile 'chain.pem' -cert 'cert.pem' -text -url 'http://ocsp.stg-int-x1.letsencrypt.org'
