# JSONPath

## TL;DR

```sh
# filter elements
# only works on arrays, not on maps
kubectl get serviceaccounts \
  -o jsonpath="{.items[?(@.metadata.name!='default')].metadata.name}"
```

## Further readings

- [JSONPath Syntax]

[jsonpath syntax]: https://support.smartbear.com/alertsite/docs/monitors/api/endpoint/jsonpath.html
