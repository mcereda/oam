# Visual Studio Code

1. [Network connections](#network-connections)
2. [Troubleshooting](#troubleshooting)
   1. [_No extensions found_ when running from source](#no-extensions-found-when-running-from-source)
3. [Further readings](#further-readings)
4. [Sources](#sources)

## Network connections

See [Network connections in Visual Studio Code].

## Troubleshooting

### _No extensions found_ when running from source

Check the `extensionsGallery` key in your fork's `product.json` file is using the official marketplace:

```sh
jq '.extensionsGallery' /usr/lib/code/product.json
```

```json
{
  "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
  "cacheUrl": "https://vscode.blob.core.windows.net/gallery/index",
  "itemUrl": "https://marketplace.visualstudio.com/items"
}
```

and if not, change them.

## Further readings

- [Network connections in Visual Studio Code]

## Sources

- [using extensions in compiled vscode]

<!-- product's references -->
[network connections in visual studio code]: https://code.visualstudio.com/docs/setup/network
[official product.json]: https://github.com/Microsoft/vscode/blob/master/product.json

<!-- internal references -->
<!-- external references -->
[using extensions in compiled vscode]: https://stackoverflow.com/questions/44057402/using-extensions-in-compiled-vscode#45291490
