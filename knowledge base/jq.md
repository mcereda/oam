# JQ

## TL;DR

```shell
# add a field
jq --arg REGION ${AWS_REGION} '.spec.template.spec.containers[]?.env? += [{name: "AWS_REGION", value: $REGION}]' /tmp/service.kube.json

# delete a field
jq 'del(.items[].spec.clusterIP)' /tmp/service.kube.json

# update a field
jq --arg NAMESPACE ${NAMESPACE} '.spec.template.spec.containers[]?.env[]? |= {name: .name, value: (if .name == "KUBERNETES_NAMESPACE" then $NAMESPACE else .value end)}' /tmp/service.kube.json

# sort keys
jq --sort-keys '.' input.json > output.json

# put specific keys on top
jq '.objects = [(.objects[] as $in | {type,name,id} + $in)]' prod/dataPipeline_deviceLocationConversion_prod.json

# convert enpass' json export to yaml file
jq '.items[] | {title, fields} | .title + ":", (.fields[] | select(.value != "") | "  " + .label + ": " + .value)' test.json -cr

# datapipeline definition refactor
for definition_file in $(find prod -type f -name "*.json")
do
  jq --sort-keys '.' ${definition_file} > /tmp/sorted.json
  jq '.objects = [(.objects[] as $in | {type,name,id} + $in | with_entries(select(.value != null)))]' /tmp/sorted.json > /tmp/reordered.json
  mv /tmp/reordered.json ${definition_file}
done

# extract data from elements with specific keys
kubectl get pods -o yaml | yq -y '.items[] | select(.metadata.name | test("^runner-.*")) | select(.spec.tolerations[].key == "component" and .spec.tolerations[].value == "big-runner") | .spec.nodeSelector, .spec.tolerations' -

# recursively find all the properties whose key is 'errors' whether it exists or not
# '..' unrolls the object, '?' checks for the value or returns null, and 'select(.)' is like a filter on truthy values
jq '[.. | .errors?[0] | select(.) ]' /tmp/helm.template.out.json

# find all images in a helm chart explicitly or implicitly using the tag 'latest'
helm template ${CHART} | yq -r '.. | .image? | select(.) | select(.|test(".*:.*")|not), select(.|test(".*:$")), select(.|test(".*:latest"))' -

## Further readings

- [Filter objects list with regex]
- [Select multiple conditions]
- [JQ recipes]

[filter objects list with regex]: https://til.hashrocket.com/posts/uv0bjiokwk-use-jq-to-filter-objects-list-with-regex
[jq recipes]: https://remysharp.com/drafts/jq-recipes
[select multiple conditions]: https://stackoverflow.com/questions/33057420/jq-select-multiple-conditions#33059058
