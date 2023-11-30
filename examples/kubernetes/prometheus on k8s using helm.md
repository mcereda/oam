# Prometheus on Kubernetes using Helm

## Table of contents <!-- omit in toc -->

1. [Usage](#usage)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Usage

Installation:

```sh
helm repo add \
  'prometheus-community' 'https://prometheus-community.github.io/helm-charts'
helm upgrade --install \
  --namespace 'monitoring' --create-namespace \
  'prometheus' 'prometheus-community/prometheus'
```

The server can be accessed via port 80 on `prometheus-server.monitoring.svc.cluster.local` from within the cluster.

Get the server URL:

```sh
export POD_NAME=$(kubectl get pods --namespace monitoring -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace monitoring port-forward $POD_NAME 9090
```

Alertmanager can be accessed via port 80 on `prometheus-alertmanager.monitoring.svc.cluster.local` from within the cluster

Get Alertmanager's URL:

```sh
export POD_NAME=$(kubectl get pods --namespace monitoring -l "app=prometheus,component=alertmanager" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace monitoring port-forward $POD_NAME 9093
```

PushGateway can be accessed via port 9091 on `prometheus-pushgateway.monitoring.svc.cluster.local` from within the cluster

Get PushGateway's URL:

```sh
export POD_NAME=$(kubectl get pods --namespace monitoring -l "app=prometheus,component=pushgateway" -o jsonpath="{.items[0].metadata.name}")
```

## Further readings

- [Helm chart]

## Sources

All the references in the [further readings] section, plus the following:

- [Install Prometheus and Grafana with helm 3 on a local machine VM]
- [Set up prometheus and ingress on kubernetes]
- [How to integrate Prometheus and Grafana on Kubernetes using Helm]

<!--
  References
  -->

<!-- Upstream -->
[helm chart]: https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Others -->
[how to integrate prometheus and grafana on kubernetes using helm]: https://semaphoreci.com/blog/prometheus-grafana-kubernetes-helm
[install prometheus and grafana with helm 3 on a local machine vm]: https://dev.to/ko_kamlesh/install-prometheus-grafana-with-helm-3-on-local-machine-vm-1kgj
[set up prometheus and ingress on kubernetes]: https://blog.gojekengineering.com/diy-how-to-set-up-prometheus-and-ingress-on-kubernetes-d395248e2ba
