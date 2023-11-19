# Postman <!-- omit in toc -->

API platform for building and using APIs.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Scripting](#scripting)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

Export environments:

1. Select `Environments` in the sidebar.
1. Select the one environment to export.
1. In the workbench, select the more actions icon (the three dots).
1. In the more actions menu, select Export.
1. Choose a path and name to download a newly generated JSON file containing the chosen environment definition.

Export or update variables from responses using those responses' test scripts:

```js
const responseJson = pm.response.json();
pm.environment.set("access_token",responseJson.access_token);
```

## Scripting

You can execute JavaScript code:

- Before a request is sent to the server, as a pre-request script under the Pre-request Script tab.
- After a response is received, as a test script under the Tests tab.

Basic examples:

```js
// Expect a specific status code.
pm.test("Response status code is 200", function () {
  pm.response.to.have.status(200);
});

// Expect specific status codes.
pm.test("Response status code is 200 or 201", () => {
  pm.expect(pm.response.code).to.be.oneOf([200,201]);
});

pm.test("Multiple assertions", () => {
  const responseJson = pm.response.json();
  pm.expect(responseJson.type).to.eql('vip');
  pm.expect(responseJson.name).to.be.a('string');
  pm.expect(responseJson.id).to.have.lengthOf('1');
});

// Export values from responses.
const responseJson = pm.response.json();
pm.environment.set("access_token",responseJson.access_token);
pm.globals.set("access_token",responseJson.access_token);
pm.collectionVariables.set("access_token",responseJson.access_token);
```

More examples [here][scripting in postman].

## Further readings

- [Website]
- [Documentation]
- [Newman], CLI Collection runner for Postman
- [Insomnia], an alternative to Postman
- [Hoppscotch], an alternative to Postman
- [Bruno], an alternative to Postman

## Sources

All the references in the [further readings] section, plus the following:

- [Scripting in Postman]
- [Exporting data from Postman]

<!--
  References
  -->

<!-- Upstream -->
[documentation]: https://learning.postman.com/docs
[exporting data from postman]: https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/
[scripting in postman]: https://learning.postman.com/docs/writing-scripts/intro-to-scripts/
[website]: https://www.postman.com/

<!-- Knowledge base -->
[bruno]: bruno.md
[hoppscotch]: hoppscotch.md
[insomnia]: insomnia.md
[newman]: newman.md
