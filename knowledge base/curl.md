# cURL

## TL;DR

```sh
# Send a single GET request and show its output on stdout.
curl http://url.of/file

# Be quiet.
curl --silent https://www.example.com
curl -s --show-error https://www.example.com

# Download files.
curl http://url.of/file -o path/to/file
curl -O http://url.of/file1 -O http://url.of/file2
curl http://url.of/file[1-24]

# Resume downloads.
curl -C - -o partial_file http://url.of/file

# Limit downloads bandwidth.
curl --limit-rate 1000B -O http://url.of/file

# Follow redirects.
curl -L http://url.of/file

# Only fetch HTTP headers from a response.
curl -I http://example.com

# Only return the HTTP status code.
curl -o /dev/null -w '%{http_code}\n' -s -I http://example.com

# Send different request types.
curl --request PUT http://example.com

# Specify headers.
curl http://example.com -H "Content-Type:application/json" http://example.com

# Skip certificate validation.
curl --insecure https://example.com

# Pass certificates for a resource.
curl --cert client.pem --key key.pem -k https://example.com
curl --cacert ca.pem https://example.com

# Authenticate.
curl -u username:password http://url.of/file
curl -u username:password -O ftp://url.of/file
curl ftp://username:password@example.com

# POST to a form.
curl -F "name=user" -F "password=test" http://example.com
curl --data 'name=bob' http://example.com/form

# Send data.
curl http://example.com -H "Content-Type:application/json" -d '{"name":"bob"}' -X POST
curl http://example.com -H "Content-Type:application/json" -d @file.json -X POST

# Use a proxy.
curl http://example.com --proxy socks5://localhost:19999

# Forcefully resolve a host to a given address.
curl https://example.com --resolve example.com:443:google.com
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

```text
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

## Sources

- [cheat.sh]
- [How to ignore invalid and self signed ssl connection errors with curl]
- [Config file]

[cheat.sh]: https://cheat.sh/curl
[config file]: https://everything.curl.dev/cmdline/configfile
[how to ignore invalid and self signed ssl connection errors with curl]: https://www.cyberciti.biz/faq/how-to-curl-ignore-ssl-certificate-warnings-command-option/
