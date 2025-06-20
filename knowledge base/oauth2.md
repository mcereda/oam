# OAuth 2.0

TODO

Intro

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Use OAuth 2.0 in an application](#use-oauth-20-in-an-application)
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

## Use OAuth 2.0 in an application

Refer [Setting up OAuth 2.0].

> [!caution]
> Google does **not** accept raw IP addresses.<br/>
> Make sure the application is configured to use a fully-qualified domain name.

1. Go to the _Clients_ part of the Google Auth Platform console.<br/>
   [Direct link](https://console.cloud.google.com/auth/clients).
1. In the upper-left corner, select a Google Cloud project if none is already.
1. Select the _Create client_ button on top of the middle section.
1. Complete the fields.

   <details>
     <summary>Example: GitLab</summary>

   ```yml
    Application type: Web application
    Name: GitLab
    Authorized JavaScript origins: https://gitlab.example.org
    Authorized redirect URIs: # the domain name, followed by the callback URIs; add one at a time
      https://gitlab.example.org/users/auth/google_oauth2/callback
      https://gitlab.example.org/-/google_api/auth/callback
   ```

   </details>

1. Select the _Create_ button.
   A window will pop up with the client ID and client secret.
1. Note the client ID and secret down or download the JSON.
1. Configure the application as appropriate.

## Further readings

- [Website]
- [Main repository]

### Sources

- [Setting up OAuth 2.0]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[main repository]: https://github.com/project/
[website]: https://website/
[setting up oauth 2.0]: https://support.google.com/googleapi/answer/6158849

<!-- Others -->
