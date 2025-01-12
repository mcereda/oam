# Hoppscotch

1. [TL;DR](#tldr)
1. [Self-hosting](#self-hosting)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
brew install --cask 'hoppscotch'
```

</details>

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

Set environment variables to use with a next request:

```js
const jsonData = pw.response.body;                // Save the JSON payload response
pw.env.set("accessToken", jsonData.access_token); // Set "accessToken" to the value of "access_token" in the response
pw.env.set("idToken", jsonData.id_token);         // Set "idToken" to the value of "id_token" in the response
```

Access the variables in the request section by referencing the variable in the format `<<variable_name>>`.

Post-request scripts == tests.

## Self-hosting

TODO

## Further readings

- [Website]
- [Codebase]
- [Documentation]

Alternatives:

- [Bruno]
- [httpie]
- [Postman]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[bruno]: bruno.md
[httpie]: httpie.md
[postman]: postman.md

<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/hoppscotch/hoppscotch
[documentation]: https://docs.hoppscotch.io/
[website]: https://hoppscotch.com/

<!-- Others -->
