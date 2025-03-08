# CloudFront

Web service speeding up distribution of static and dynamic web content such as `.html`, `.css`, `.js`, and image files.

1. [TL;DR](#tldr)
1. [Edge functions](#edge-functions)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details style="padding-bottom: 1em;">
  <summary>Glossary</summary>

| Term         | Summary                                                        |
| ------------ | -------------------------------------------------------------- |
| Distribution | FIXME                                                          |
| Origin       | Location where the original version of one's content is stored |
| Viewer       | End user or otherwise client that make requests                |

</details>

Caches web content from one's defined _origins_ and delivers it through edge locations.<br/>
When requesting content served with CloudFront, requests are routed to the edge location with the lowest latency for the
client.

If the content is already in the edge location with the lowest latency, CloudFront delivers it immediately.<br/>
If the content is not in that edge location, CloudFront retrieves it from the _origin_ defined for it.

Origins can be S3 buckets, MediaPackage channels, or HTTP servers.<br/>
Each distribution can have by default up to 25 origins.

Every origin that is **not** an AWS service is a _custom origin_.<br/>
Custom origins **require** configuring their ports' and protocols' settings.

<details>
  <summary>Create Distributions</summary>

1. Set up one or more origins so that they serve their content normally.
1. Create a CloudFront Distribution.<br/>
   This usually takes 15 to 30 minutes.

</details>

<details style="padding: 0 0 1em 0;">
  <summary>[optional] Avoid using the provided Distribution's domain name</summary>

1. Configure _alternate domain names_ so that the Distribution accepts requests for those aliases.
1. Provide a SSL/TLS certificate for the alternate domain names.
1. Create DNS records of type CNAME pointing to the provided Distribution's domain name.

Adding the SSL/TLS certificate verifies the requirement that one owns the domain name or has authorization to use it.

</details>

One **cannot** configure CloudFront to add specific headers to requests that it forwards to origins.<br/>
Refer [Custom headers that CloudFront can't add to origin requests] for the updated list.

<details style="padding: 0 0 1em 1em;">

- `Cache-Control`
- `Connection`
- `Content-Length`
- `Cookie`
- `Host`
- `If-Match`
- `If-Modified-Since`
- `If-None-Match`
- `If-Range`
- `If-Unmodified-Since`
- `Max-Forwards`
- `Pragma`
- `Proxy-Authenticate`
- `Proxy-Authorization`
- `Proxy-Connection`
- `Range`
- `Request-Range`
- `TE`
- `Trailer`
- `Transfer-Encoding`
- `Upgrade`
- `Via`
- `Headers that begin with X-Amz-`
- `Headers that begin with X-Edge-`
- `X-Real-Ip`

</details>

To make changes to _those_ headers, leverage [edge functions].

When deleting an origin, first edit or delete all cache behaviors that are associated with that origin.

## Edge functions

Refer [Customize at the edge with functions].

Code that one writes and attaches to one or more CloudFront distributions.<br/>
It customizes how attached CloudFront distributions process HTTP requests and responses.<br/>
Examples include manipulating requests and responses flowing through CloudFront, performing basic authentication and
authorization, and generating HTTP responses at the edge.

The functions run close to viewers to minimize latency.<br/>
One will **not** need to manage servers or other infrastructure for them.

Functions are served as:

- _CloudFront Functions_: lightweight functions in JavaScript executed as a native feature of CloudFront.<br/>
  They offer sub-millisecond startup times, immediate scale-up to millions of requests per second, execution in a highly
  secure environment, and code development entirely within CloudFront.<br/>
  Those functions are supposed to be **simple** and **lightweight**.
- _Lambda@Edge_: extension of the Lambda service.<br/>
  It offers computing for **complex** functions and **full** application logic closer to viewers, executed in a highly
  secure environment.<br/>
  Those functions can run in Node.js or Python runtime environments, and are replicated to all regions when associated
  with a distribution.

If running AWS WAF on CloudFront, one can use WAF's inserted headers for both CloudFront Functions and Lambda@Edge.<br/>
This works for both viewer and origin, both for requests and responses.

Each event type (_viewer request_, _origin request_, _origin response_, and _viewer response_) can be associated to
**one and only one** edge function.

One **cannot** combine CloudFront Functions and Lambda@Edge in _viewer_ events.

CloudFront does **not** invoke edge functions for _viewer response_ events when the origin returns HTTP status code 400
or higher.<br/>
Lambda@Edge functions for _origin response_ events are invoked for **all** origin responses, including when the origin
returns HTTP status code 400 or higher.

Certain HTTP headers are **not** exposed to edge functions, and functions **cannot** add them.<br/>
Should a function add such a _disallowed header_, requests will fail CloudFront's validation and CloudFront will return
HTTP status code 502 (Bad Gateway) to the viewer.

Certain headers are _can_ be read by functions, but functions **cannot** add, modify, nor delete them.<br/>
Should a function add or edit such a _read-only header_, requests will fail CloudFront's validation and CloudFront will
return HTTP status code 502 (Bad Gateway) to the viewer.<br/>
`Host` is one of those headers.

Refer [Restrictions on all edge functions - HTTP headers] for the updated list of disallowed and read-only headers.

<details style="padding-left: 1em;">

  <details style="padding-left: 1em;">
    <summary>Disallowed headers</summary>

For all function types:

- `Connection`
- `Expect`
- `Keep-Alive`
- `Proxy-Authenticate`
- `Proxy-Authorization`
- `Proxy-Connection`
- `Trailer`
- `Upgrade`
- `X-Accel-Buffering`
- `X-Accel-Charset`
- `X-Accel-Limit-Rate`
- `X-Accel-Redirect`
- `X-Amz-Cf-*`
- `X-Amzn-Auth`
- `X-Amzn-Cf-Billing`
- `X-Amzn-Cf-Id`
- `X-Amzn-Cf-Xff`
- `X-Amzn-Errortype`
- `X-Amzn-Fle-Profile`
- `X-Amzn-Header-Count`
- `X-Amzn-Header-Order`
- `X-Amzn-Lambda-Integration-Tag`
- `X-Amzn-RequestId`
- `X-Cache`
- `X-Edge-*`
- `X-Forwarded-Proto`
- `X-Real-IP`

  </details>

  <details style="padding-left: 1em;">
    <summary>Read-only headers</summary>

    <details style="padding-left: 1em;">
      <summary>In <i>viewer request</i> events</summary>

For all function types:

- `Content-Length`
- `Host`
- `Transfer-Encoding`
- `Via`

    </details>

    <details style="padding-left: 1em;">
      <summary>In <i>viewer response</i> events</summary>

For all function types:

- `Warning`
- `Via`

Lambda@Edge only:

- `Content-Length`
- `Content-Encoding`
- `Transfer-Encoding`

    </details>

    <details style="padding-left: 1em;">
      <summary>In <i>origin request</i> events</summary>

Lambda@Edge only:

- `Accept-Encoding`
- `Content-Length`
- `If-Modified-Since`
- `If-None-Match`
- `If-Range`
- `If-Unmodified-Since`
- `Transfer-Encoding`
- `Via`

    </details>

    <details style="padding-left: 1em;">
      <summary>In <i>origin response</i> events</summary>

Lambda@Edge only:

- `Transfer-Encoding`
- `Via`

    </details>

  </details>

</details>

## Further readings

### Sources

- [Customize at the edge with functions]
- [Restrictions on all edge functions]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[edge functions]: #edge-functions

<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[custom headers that cloudfront can't add to origin requests]: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/add-origin-custom-headers.html#add-origin-custom-headers-denylist
[customize at the edge with functions]: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/edge-functions.html
[restrictions on all edge functions - http headers]: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/edge-function-restrictions-all.html#function-restrictions-headers
[restrictions on all edge functions]: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/edge-function-restrictions-all.html

<!-- Others -->
