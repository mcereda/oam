# Visual Studio Code

## Troubleshooting

### _No extensions found_ when running from source

Check the `extensionsGallery` key in your fork's `product.json` file is using the official marketplace:

```sh
jq '.extensionsGallery' /usr/lib/code/product.json
{
  "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
  "cacheUrl": "https://vscode.blob.core.windows.net/gallery/index",
  "itemUrl": "https://marketplace.visualstudio.com/items"
}
```

and if not, change them.

## Sources

- [using extensions in compiled vscode]

[using extensions in compiled vscode]: https://stackoverflow.com/questions/44057402/using-extensions-in-compiled-vscode#45291490

[official product.json]: https://github.com/Microsoft/vscode/blob/master/product.json
