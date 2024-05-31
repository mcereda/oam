#!/usr/bin/env sh

# Sources:
# - https://everything.curl.dev/usingcurl/connections/name.html

# Use different names.
# Kinda like '--resolve' but to aliases and supports ports.
curl --connect-to 'super.fake.domain:443:localhost:8443' 'https://super.fake.domain'

# Forcefully resolve hosts to given addresses.
# The resolution *must* be an address, not an FQDN.
curl --resolve 'super.fake.domain:8443:127.0.0.1' 'https://super.fake.domain:8443'
