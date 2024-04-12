# JSONPath

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Filter elements.
# Only works on arrays, not on maps.
kubectl get serviceaccounts \
  -o jsonpath="{.items[?(@.metadata.name!='default')].metadata.name}"
```

## Further readings

- [JSONPath Syntax]
- [How to extract values using a JSON Path Expression from the Response Body in Rungutan]

<!--
  References
  -->

<!-- Others -->
[how to extract values using a json path expression from the response body in rungutan]: https://rungutan.com/blog/extract-value-json-path-expression/
[jsonpath syntax]: https://support.smartbear.com/alertsite/docs/monitors/api/endpoint/jsonpath.html
