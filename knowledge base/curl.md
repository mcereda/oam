# cURL

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Apply settings to all connections](#apply-settings-to-all-connections)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Send single GET requests and show their output on stdout.
curl 'http://url.of/file'
curl 'https://www.example.com'

# Be quiet.
curl … --silent
curl … -s --show-error

# Download files to specific paths.
curl … --output 'path/to/file'
curl … -o 'path/to/file'

# Download files reusing their name for output.
curl … --remote-name 'http://url.of/file1' -O 'http://url.of/file2'
curl … -O http://url.of/file[1-24]

# Resume downloads.
curl … --continue-at -
curl … -o 'partial_file' -C -

# Limit downloads bandwidth.
curl … --limit-rate '1000B'

# Follow redirects.
curl … --location
curl … -L

# Only fetch the response's HTTP headers.
# Prevents downloading the response's body.
curl … --head
curl … -I

# Write specific information in output.
curl … … --write-out '@template.file'
curl … -w 'request returned %{http_code}\nDownloaded %{size_download} bytes\n'

# Send different request types.
curl … --request 'PUT'
curl … -X 'GET'

# Specify headers.
curl … -H 'Content-Type:application/json'
curl … --header 'Content-Type:application/json'

# Fail fast with no output.
# Returns the HTTP error code.
curl … --fail
curl … -f

# Skip certificate validation.
curl … --insecure
curl … -k

# Pass certificates for a resource.
curl … --cert 'client.pem' --key 'key.pem'
curl … --cacert 'ca.pem'

# Authenticate.
curl 'http://url.of/file' --user 'username':'password'
curl 'ftp://url.of/file' -u 'username':'password' -O
curl 'ftp://username:password@example.com'

# Send data.
curl … -X 'POST' -H "Content-Type:application/json" --data '@file.json'
curl … -d '{"name": "bob"}'
curl … -d 'name=bob'

# POST to forms.
curl … --form 'name=user' -F 'password=test'
curl … -d 'name=bob' -F 'password=@password.file'

# Use proxies.
curl … --proxy 'socks5://localhost:19999'

# Forcefully resolve hosts to given addresses.
# The resolution *must* be an address, not an FQDN.
curl … --resolve 'super.fake.domain:8443:127.0.0.1' 'https://super.fake.domain:8443'

# Use different names.
# Kinda like '--resolve' but to aliases and supports ports.
curl … --connect-to 'super.fake.domain:443:localhost:8443' 'https://super.fake.domain'

# Ask kindly to use HTTP/2.
curl … --http2

# Force the use of HTTP/2.
curl … --http2-prior-knowledge
```

## Apply settings to all connections

Unless the `-q` option is used, `curl` always checks for a default config file on invocation and uses it if found.

The default configuration file is looked for in the following places, in this order:

1. `$CURL_HOME/.curlrc`
1. `$XDG_CONFIG_HOME/.curlrc`, added in 7.73.0
1. `$HOME/.curlrc`
1. on Windows only: `%USERPROFILE%\.curlrc`
1. on Windows only: `%APPDATA%\.curlrc`
1. on Windows only: `%USERPROFILE%\Application Data\.curlrc`

On Non-Windows hosts, `curl` uses `getpwuid` to find the user's home directory.

On Windows, if curl finds no `.curlrc` file in the sequence described above, it will check for one in the same dir the
`curl` executable is placed.

```txt
# ~/.curlrc
# Accepts both short and long options.
# Options in long format are accepted without the leading two dashes to make it
# easier to read.
# Arguments must be provided on the same line of the option.
# Arguments can be separated by space, '=' and ':'

location
--insecure
--user-agent "my-agent"
request = "PUT"
config: "~/.config/curl"
```

## Further readings

- [Book]

### Sources

- [cheat.sh]
- [How to ignore invalid and self signed ssl connection errors with curl]
- [Config file]
- [HTTP2]
- [Name resolve tricks]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[book]: https://everything.curl.dev/
[config file]: https://everything.curl.dev/cmdline/configfile
[http2]: https://everything.curl.dev/http/versions/http2

<!-- Others -->
[cheat.sh]: https://cheat.sh/curl
[how to ignore invalid and self signed ssl connection errors with curl]: https://www.cyberciti.biz/faq/how-to-curl-ignore-ssl-certificate-warnings-command-option/
[name resolve tricks]: https://everything.curl.dev/usingcurl/connections/name.html
