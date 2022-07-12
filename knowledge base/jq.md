# JQ

## TL;DR

```sh
# Add a key.
jq --arg REGION ${AWS_REGION} '.spec.template.spec.containers[]?.env? += [{name: "AWS_REGION", value: $REGION}]' /tmp/service.kube.json

# Delete a key.
jq 'del(.items[].spec.clusterIP)' /tmp/service.kube.json

# Change a value.
jq '.extensionsGallery
    | .serviceUrl |= "https://marketplace.visualstudio.com/_apis/public/gallery"' \
  /usr/lib/code/product.json
jq --arg NAMESPACE ${NAMESPACE} '.spec.template.spec.containers[]?.env[]? |= {name: .name, value: (if .name == "KUBERNETES_NAMESPACE" then $NAMESPACE else .value end)}' /tmp/service.kube.json

# Change multiple values at once.
jq '.extensionsGallery
    | .serviceUrl = "https://marketplace.visualstudio.com/_apis/public/gallery"
    | .cacheUrl = "https://vscode.blob.core.windows.net/gallery/index"
    | .itemUrl = "https://marketplace.visualstudio.com/items"' \
  /usr/lib/code/product.json
jq '.extensionsGallery + {
       serviceUrl: "https://marketplace.visualstudio.com/_apis/public/gallery",
       cacheUrl: "https://vscode.blob.core.windows.net/gallery/index",
       itemUrl: "https://marketplace.visualstudio.com/items"
    }' /usr/lib/code/product.json

# Sort all the keys.
jq --sort-keys '.' input.json > output.json

# Put specific keys on top.
jq '.objects = [(.objects[] as $in | {type,name,id} + $in)]' prod/dataPipeline_deviceLocationConversion_prod.json

# Convert Enpass' JSON export to a YAML file
jq '.items[] | {title, fields} | .title + ":", (.fields[] | select(.value != "") | "  " + .label + ": " + .value)' test.json -cr

# Refactor a datapipeline definition.
jq --sort-keys '.' datapipeline.json > /tmp/sorted.json \
&& jq '.objects = [(.objects[] as $in | {type,name,id} + $in | with_entries(select(.value != null)))]' \
     /tmp/sorted.json > /tmp/reordered.json \
&& mv /tmp/reordered.json datapipeline.json

# Extract the value of elements with specific keys.
kubectl get pods -o yaml \
| yq -y '
    .items[]
    | select(.metadata.name | test("^runner-.*"))
    | select(.spec.tolerations[].key == "component" and .spec.tolerations[].value == "big-runner")
    | .spec.nodeSelector, .spec.tolerations' \
    -

# Recursively find all the properties whose key is 'errors' whether it exists or not.
# '..' unrolls the object, '?' checks for the value or returns null, and 'select(.)' is like a filter on truthy values.
jq '[.. | .errors?[0] | select(.) ]' /tmp/helm.template.out.json

# Find all images in a helm chart explicitly or implicitly using the tag 'latest'.
helm template chartName \
| yq -r '
    ..
    | .image?
    | select(.)
    | select(.|test(".*:.*")|not), select(.|test(".*:$")), select(.|test(".*:latest"))' \
    -
```

## Further readings

- [JQ recipes]

[jq recipes]: https://remysharp.com/drafts/jq-recipes

## Sources

- [Filter objects list with regex]
- [Select multiple conditions]
- [Change multiple values at once]

[change multiple values at once]: https://stackoverflow.com/questions/47355901/jq-change-multiple-values#47357956
[filter objects list with regex]: https://til.hashrocket.com/posts/uv0bjiokwk-use-jq-to-filter-objects-list-with-regex
[select multiple conditions]: https://stackoverflow.com/questions/33057420/jq-select-multiple-conditions#33059058
