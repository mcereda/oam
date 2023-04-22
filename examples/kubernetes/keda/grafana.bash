#!/usr/bin/env bash

## tested on macosx using minikube 1.17.0 and k8s v1.20.2 on Docker 20.10.2

set -ex

minikube start --cpus 4 --memory 4GiB --vm
minikube addons enable metrics-server
minikube addons enable ingress

kubectl patch deployments.apps --namespace kube-system ingress-nginx-controller --patch '
spec:
  template:
    metadata:
      annotations:
        prometheus.io/port: "10254"
        prometheus.io/scrape: "true"
'

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

cat > /tmp/demo.keda.grafana.values.yaml <<EOF
adminPassword: qwerty
ingress:
  enabled: true
  hosts:
    - grafana
EOF

helm upgrade --install --namespace monitoring --create-namespace prometheus prometheus-community/prometheus --wait
helm upgrade --install --namespace monitoring --create-namespace grafana grafana/grafana --values /tmp/demo.keda.grafana.values.yaml --wait
helm upgrade --install --namespace scaling --create-namespace keda kedacore/keda --version 2.0.0 --wait

cat > /tmp/demo.keda.scaledobject.yaml <<EOF
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: grafana
  namespace: monitoring
spec:
  scaleTargetRef:
    name: grafana
  minReplicaCount: 1
  maxReplicaCount: 5
  pollingInterval: 2
  advanced:
    restoreToOriginalReplicaCount: true
    horizontalPodAutoscalerConfig:
      behavior:
        scaleDown:
          stabilizationWindowSeconds: 3
          policies:
          - type: Percent
            value: 100
            periodSeconds: 5
        scaleUp:
          stabilizationWindowSeconds: 3
          policies:
          - type: Percent
            value: 100
            periodSeconds: 5
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus-server.monitoring
      metricName: nginx_ingress_controller_requests
      query: sum(rate(nginx_ingress_controller_requests{ingress="grafana"}[2m]))
      threshold: '10'
EOF
# HPA behavior is available from K8S v1.18.0. Delete the
# spec.advanced.horizontalPodAutoscalerConfig key if using a previous version
if [[ $(kubectl version --short --output json | jq -r '.serverVersion.minor' -) -lt 18 ]]; then
  yq -y 'del(.spec.advanced.horizontalPodAutoscalerConfig)' /tmp/demo.keda.scaledobject.yaml | kubectl apply --filename -
else
  kubectl apply --filename /tmp/demo.keda.scaledobject.yaml
fi
watch "kubectl get scaledobject.keda.sh/grafana --namespace monitoring"
watch "kubectl get horizontalpodautoscalers.autoscaling --namespace monitoring keda-hpa-grafana"

echo "$(minikube ip) grafana" | sudo tee -a /etc/hosts
while true; do ab -n 750 -c 1 http://grafana/; sleep 10; done

exit 0

# ---------------
# troubleshooting
# ---------------

# check the query on prometheus
kubectl apply --filename - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus
  namespace: monitoring
spec:
  rules:
  - host: prometheus
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-server
            port:
              number: 80
EOF
open http://prometheus

# check the deployment is being watched
kubectl logs --namespace scaling $(kubectl get pods --namespace scaling | grep -v metrics-apiserver | sed 1d | cut -d ' ' -f 1)

# check grafana's ingress stats
curl "http://grafana/api/datasources" --request POST --user admin:qwerty --header "Content-Type: application/json" --data '{
  "name": "Prometheus",
  "type": "prometheus",
  "access": "proxy",
  "url": "http://prometheus-server"
}'
curl "https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/grafana/dashboards/nginx.json" | pbcopy
open http://grafana/
# import a dashboard pasting the clipboard's content
