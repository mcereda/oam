# JQ

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Only list keys.
jq 'keys' 'file.json'

# Sort all the keys.
jq --sort-keys '.' 'input.json' > 'output.json'
jq --sort-keys '.' 'file.json' | sponge 'file.json'

# Avoid failure due to possibly missing keys.
# Notice the postfix operator '?'.
jq '.spec.template.spec.containers[]?.env?' 'manifest.kube.json'

# Add elements to lists.
jq '.orchestrators += [{"orchestratorVersion": "1.24.9"}]'
jq --arg REGION ${AWS_REGION} '.spec.template.spec.containers[]?.env? += [{name: "AWS_REGION", value: $REGION}]' /tmp/service.kube.json

# Delete keys from objects.
jq 'del(.items[].spec.clusterIP)' /tmp/service.kube.json
jq 'del(.country, .number, .language)' …
# Remember ranges are **exclusive** of the end index.
jq 'del(.[0,1,2])' …
jq 'del(.[0:3])' …

# Remove all null values.
jq 'del(..|nulls)' …
jq 'del(recurse(.[]?;true)|select(. == null))' …

# Print objects as 'key [space] "value"' pairs.
jq -r 'to_entries[] | "\(.key) \"\(.value)\""' 'file.json'

# Change single values.
# A.K.A. update values.
jq '.extensionsGallery
    | .serviceUrl |= "https://marketplace.visualstudio.com/_apis/public/gallery"' \
  /usr/lib/code/product.json
jq --arg NAMESPACE ${NAMESPACE} \
  '.spec.template.spec.containers[]?.env[]? |= {name: .name, value: (if .name == "KUBERNETES_NAMESPACE" then $NAMESPACE else .value end)}' \
  /tmp/service.kube.json

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

# Merge objects from 2 files
jq '.[0] * .[1]' '1.json' '2.json'

# Only show ('select') elements which specific attribute's value is in a list.
jq '.[]|select(.PrivateIpAddress|IN("172.31.6.209","172.31.6.229"))|.PrivateDnsName'

# Add elements from arrays with the same name from other files.
jq '.rules=([input.rules]|flatten)' starting-rule-set.json ending-rule-set.json
jq '.rules=([inputs.rules]|flatten)' starting-rule-set.json parts/*.json

# Put specific keys on top.
jq '.objects = [(.objects[] as $in | {type,name,id} + $in)]' prod/dataPipeline_deviceLocationConversion_prod.json

# Convert Enpass' JSON export to a YAML file
jq '.items[] | {title, fields} | .title + ":", (.fields[] | select(.value != "") | "  " + .label + ": " + .value)' test.json -cr

# Refactor an AWS DataPipeline definition.
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

# Check that the 'backend.url key' in a 'Pulumi.yaml' file is not 'file://' and fail otherwise.
yq -e '(.backend.url|test("^file://")?)|not' 'Pulumi.yaml'
```

## Further readings

- [JQ recipes]

[jq recipes]: https://remysharp.com/drafts/jq-recipes

### Sources

- [Filter objects list with regex]
- [Select multiple conditions]
- [Change multiple values at once]
- [jq Select range]
- [Deleting multiple keys at once with jq]
- [Remove all null values]
- [jq: select where .attribute in list]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Others -->
[change multiple values at once]: https://stackoverflow.com/questions/47355901/jq-change-multiple-values#47357956
[deleting multiple keys at once with jq]: https://stackoverflow.com/questions/36227245/deleting-multiple-keys-at-once-with-jq
[filter objects list with regex]: https://til.hashrocket.com/posts/uv0bjiokwk-use-jq-to-filter-objects-list-with-regex
[jq select range]: https://stackoverflow.com/questions/45548604/jq-select-range
[jq: select where .attribute in list]: https://stackoverflow.com/questions/50750688/jq-select-where-attribute-in-list
[remove all null values]: https://stackoverflow.com/questions/39500608/remove-all-null-values
[select multiple conditions]: https://stackoverflow.com/questions/33057420/jq-select-multiple-conditions#33059058
