# JSONPath

## TL;DR

```sh
# Filter elements.
# Only works on arrays, not on maps.
kubectl get serviceaccounts \
  -o jsonpath="{.items[?(@.metadata.name!='default')].metadata.name}"
```

## Further readings

- [JSONPath Syntax]
- [Live editor]

[jsonpath syntax]: https://support.smartbear.com/alertsite/docs/monitors/api/endpoint/jsonpath.html
[live editor]: https://json8.github.io/patch/demos/apply/
