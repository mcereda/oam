# HTTP

TODO

Intro

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Response status codes](#response-status-codes)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

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

## Response status codes

> [!note]
> Response codes not listed here are either just missing or non-standard responses, possibly custom to the server.

| Code | Message                         | Summary                                                                                           |
| ---- | ------------------------------- | ------------------------------------------------------------------------------------------------- |
| 100  | Continue                        | FIXME                                                                                             |
| 101  | Switching Protocols             | FIXME                                                                                             |
| 102  | Processing                      | FIXME                                                                                             |
| 103  | Early Hints                     | FIXME                                                                                             |
| 200  | OK                              | FIXME                                                                                             |
| 201  | Created                         | FIXME                                                                                             |
| 202  | Accepted                        | FIXME                                                                                             |
| 203  | Non-Authoritative Information   | FIXME                                                                                             |
| 204  | No Content                      | FIXME                                                                                             |
| 205  | Reset Content                   | FIXME                                                                                             |
| 206  | Partial Content                 | FIXME                                                                                             |
| 207  | Multi-Status                    | FIXME                                                                                             |
| 208  | Already Reported                | FIXME                                                                                             |
| 226  | IM Used                         | FIXME                                                                                             |
| 300  | Multiple Choices                | FIXME                                                                                             |
| 301  | Moved Permanently               | FIXME                                                                                             |
| 302  | Found                           | FIXME                                                                                             |
| 303  | See Other                       | FIXME                                                                                             |
| 304  | Not Modified                    | FIXME                                                                                             |
| 307  | Temporary Redirect              | FIXME                                                                                             |
| 308  | Permanent Redirect              | FIXME                                                                                             |
| 400  | Bad Request                     | FIXME                                                                                             |
| 401  | Unauthorized                    | FIXME                                                                                             |
| 402  | Payment Required                | FIXME                                                                                             |
| 403  | Forbidden                       | FIXME                                                                                             |
| 404  | Not Found                       | FIXME                                                                                             |
| 405  | Method Not Allowed              | FIXME                                                                                             |
| 406  | Not Acceptable                  | FIXME                                                                                             |
| 407  | Proxy Authentication Required   | FIXME                                                                                             |
| 408  | Request Timeout                 | FIXME                                                                                             |
| 409  | Conflict                        | FIXME                                                                                             |
| 410  | Gone                            | FIXME                                                                                             |
| 411  | Length Required                 | FIXME                                                                                             |
| 412  | Precondition Failed             | FIXME                                                                                             |
| 413  | Content Too Large               | FIXME                                                                                             |
| 414  | URI Too Long                    | FIXME                                                                                             |
| 415  | Unsupported Media Type          | FIXME                                                                                             |
| 416  | Range Not Satisfiable           | FIXME                                                                                             |
| 417  | Expectation Failed              | FIXME                                                                                             |
| 418  | I'm a teapot                    | Returned by teapots requested to brew coffee.<br/>Refer [Hyper Text Coffee Pot Control Protocol]. |
| 421  | Misdirected Request             | FIXME                                                                                             |
| 422  | Unprocessable Content           | FIXME                                                                                             |
| 423  | Locked                          | FIXME                                                                                             |
| 424  | Failed Dependency               | FIXME                                                                                             |
| 425  | Too Early                       | FIXME                                                                                             |
| 426  | Upgrade Required                | FIXME                                                                                             |
| 428  | Precondition Required           | FIXME                                                                                             |
| 429  | Too Many Requests               | FIXME                                                                                             |
| 431  | Request Header Fields Too Large | FIXME                                                                                             |
| 451  | Unavailable For Legal Reasons   | FIXME                                                                                             |
| 500  | Internal Server Error           | FIXME                                                                                             |
| 501  | Not Implemented                 | FIXME                                                                                             |
| 502  | Bad Gateway                     | FIXME                                                                                             |
| 503  | Service Unavailable             | FIXME                                                                                             |
| 504  | Gateway Timeout                 | FIXME                                                                                             |
| 505  | HTTP Version Not Supported      | FIXME                                                                                             |
| 506  | Variant Also Negotiates         | FIXME                                                                                             |
| 507  | Insufficient Storage            | FIXME                                                                                             |
| 508  | Loop Detected                   | FIXME                                                                                             |
| 510  | Not Extended                    | FIXME                                                                                             |
| 511  | Network Authentication Required | FIXME                                                                                             |

## Further readings

- [HTTP response status codes]
- [http.cat]
- [Hyper Text Coffee Pot Control Protocol]

### Sources

- [How Does HTTPS Work? RSA Encryption Explained]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->

<!-- Others -->
[how does https work? rsa encryption explained]: https://tiptopsecurity.com/how-does-https-work-rsa-encryption-explained/
[HTTP response status codes]: https://developer.mozilla.org/nl/docs/Web/HTTP/Status
[http.cat]: https://http.cat/
[Hyper Text Coffee Pot Control Protocol]: https://en.wikipedia.org/wiki/Hyper_Text_Coffee_Pot_Control_Protocol
