# Helm

Package manager for Kubernetes.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Start managing existing resources with a specific helm chart](#start-managing-existing-resources-with-a-specific-helm-chart)
1. [Further readings](#further-readings)

## TL;DR

```sh
# List installed plugins.
helm plugin list
helm plugin ls

# Install new plugins.
helm plugin add 'https://github.com/author/plugin'
helm plugin install 'path/to/plugin'

# Update installed plugins.
helm plugin update 'plugin_name'
helm plugin up 'plugin_name'

# Uninstall plugins.
helm plugin rm 'plugin_name'
helm plugin remove 'plugin_name'
helm plugin uninstall 'plugin_name'


# List added repositories.
helm repo list

# Add repositories.
helm repo add 'grafana' 'https://grafana.github.io/helm-charts'
helm repo add 'ingress-nginx' 'https://kubernetes.github.io/ingress-nginx'

# Update repositories.
helm repo update
helm repo update 'keda'

# Remove repositories.
helm repo remove 'prometheus'


# Search for specific charts
helm search hub --max-col-width '100' 'ingress-nginx'
helm search repo 'grafana'
helm search repo --versions 'grafana/grafana'

# Download and extract charts.
helm pull 'grafana/grafana'
helm pull 'ingress-nginx/ingress-nginx' --version '4.0.6' \
  --destination '/tmp' \
  --untar --untardir 'extracted/chart'

# Get the default values of specific charts.
helm inspect values 'gitlab/gitlab'


# Install releases
helm install 'my-gitlab' 'gitlab/gitlab'
helm upgrade --install 'my-gitlab' 'gitlab/gitlab'
helm install --atomic --values 'values.yaml' 'my-gitlab' 'gitlab/gitlab'
helm install --set 'value=key' 'my-gitlab' 'gitlab/gitlab'

# Install charts without adding their repository.
helm upgrade --install 'keda' 'keda' \
  --repo 'https://kedacore.github.io/charts' \
  --namespace 'keda' --create-namespace

# Upgrade deployed releases.
helm upgrade --install 'my-wordpress' 'wordpress'
helm upgrade --values 'values.yaml' 'my-wordpress' 'wordpress'
helm upgrade --namespace 'gitlab' --values 'values.yaml' 'gitlab gitlab/gitlab' --dry-run
helm upgrade --atomic --create-namespace --namespace 'gitlab' --timeout 0 --values 'values.yaml' 'gitlab' 'gitlab/gitlab' --debug

# Inspect deployed releases' manifests.
helm get manifest 'wordpress'
```

## Start managing existing resources with a specific helm chart

Since `helm` 3.2 it's possible to import/adopt existing resources into a helm release.<br/>
To achieve this:

1. create your helm release **leaving out** the needed existing resources
1. add the following annotation and labels to the existing resources:

   ```yaml
   annotations:
     meta.helm.sh/release-name: app-release-name
     meta.helm.sh/release-namespace: app-deployment-namespace-name
   labels:
     app.kubernetes.io/managed-by: Helm
   ```

   with `app-release-name` being the release name used to deploy the helm chart and `app-deployment-namespace-name` being the deployment namespace.

   ```sh
   kubectl annotate "$KIND" "$NAME" "meta.helm.sh/release-name=${RELEASE_NAME}"
   kubectl annotate "$KIND" "$NAME" "meta.helm.sh/release-namespace=$NAMESPACE"
   kubectl label "$KIND" "$NAME" "app.kubernetes.io/managed-by=Helm"
   ```

1. now, add the existing resources' manifests to the chart
1. execute a chart upgrade:

   ```sh
   helm upgrade 'app-release-name'
   ```

## Further readings

- [Website]
- [Kubernetes]
- [Helmfile]

<!--
  References
  -->

<!-- Upstream -->
[website]: https://helm.sh/

<!-- Knowledge base -->
[helmfile]: helmfile.md
[kubernetes]: README.md
