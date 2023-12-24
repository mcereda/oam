# cURL

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Apply settings to all connections](#apply-settings-to-all-connections)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Send a single GET request and show its output on stdout.
curl 'http://url.of/file'

# Be quiet.
curl 'https://www.example.com' … --silent
curl … -s --show-error

# Download files to specific paths.
curl 'http://url.of/file' --output 'path/to/file'
curl … -o 'path/to/file'

# Download files reusing their name for output.
curl … --remote-name 'http://url.of/file1' -O 'http://url.of/file2'
curl … -O http://url.of/file[1-24]

# Resume downloads.
curl 'http://url.of/file' --continue-at -
curl … -o 'partial_file' -C -

# Limit downloads bandwidth.
curl 'http://url.of/file' --limit-rate '1000B'

# Follow redirects.
curl 'http://url.of/file' --location
curl … -L

# Only fetch the response's HTTP headers.
# Prevents downloading the response's body.
curl 'http://example.com' --head
curl … -I

# Write specific information in output.
curl 'http://example.com' … --write-out '@template.file'
curl … -w 'request returned %{http_code}\nDownloaded %{size_download} bytes\n'

# Send different request types.
curl 'http://example.com' --request 'PUT'
curl … -X 'GET'

# Specify headers.
curl 'http://example.com' -H 'Content-Type:application/json'
curl … --header 'Content-Type:application/json'

# Fail fast with no output.
# Returns the HTTP error code.
curl 'http://example.com' --fail
curl … -f

# Skip certificate validation.
curl 'https://example.com' --insecure
curl … -k

# Pass certificates for a resource.
curl 'https://example.com' --cert 'client.pem' --key 'key.pem'
curl … --cacert 'ca.pem'

# Authenticate.
curl 'http://url.of/file' --user 'username':'password'
curl 'ftp://url.of/file' -u 'username':'password' -O
curl 'ftp://username:password@example.com'

# Send data.
curl 'http://example.com' -X 'POST' -H "Content-Type:application/json" --data '@file.json'
curl … -d '{"name": "bob"}'
curl … -d 'name=bob'

# POST to a form.
curl 'http://example.com' --form 'name=user' -F 'password=test'
curl … -d 'name=bob' -F 'password=@password.file'

# Use a proxy.
curl 'http://example.com' --proxy 'socks5://localhost:19999'

# Forcefully resolve a host to a given address.
curl 'https://example.com' --resolve 'example.com:443:google.com'

# Ask to use HTTP/2.
curl 'https://example.com' --http2

# Force the use of HTTP/2.
curl 'https://example.com' --http2-prior-knowledge
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

On Windows, if curl finds no `.curlrc` file in the sequence described above, it will check for one in the same dir the curl executable is placed.

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

## Sources

All the references in the [further readings] section, plus the following:

- [cheat.sh]
- [How to ignore invalid and self signed ssl connection errors with curl]
- [Config file]
- [HTTP2]

<!--
  References
  -->

<!-- Upstream -->
[book]: https://everything.curl.dev/
[config file]: https://everything.curl.dev/cmdline/configfile
[http2]: https://everything.curl.dev/http/versions/http2

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Others -->
[cheat.sh]: https://cheat.sh/curl
[how to ignore invalid and self signed ssl connection errors with curl]: https://www.cyberciti.biz/faq/how-to-curl-ignore-ssl-certificate-warnings-command-option/
