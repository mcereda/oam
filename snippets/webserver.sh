#!/usr/bin/env sh

# sources:
# - https://anvileight.com/blog/posts/simple-python-http-server/

# Quick 'n' dirty http-only web server
# No TLS support
python -m 'http.server'
python -m 'http.server' '8080' --bind 'localhost' --directory '/files/to/serve' --protocol 'HTTP/1.1' --cgi

# Quick 'n' dirty web server
# https://twisted.org/
# pip install --user 'twisted[tls]'
twistd -no web
twistd -no web --path '/files/to/serve' --https '8443' --certificate 'server.pem' --privkey 'server.pem'
