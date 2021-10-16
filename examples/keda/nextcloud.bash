#!/usr/bin/env bash

set -ex

# minikube start --cpus 4 --memory 4GiB --vm
# minikube addons enable ingress
# minikube addons enable metrics-server

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kedacore https://kedacore.github.io/charts
helm repo add nextcloud https://nextcloud.github.io/helm/
helm repo update

helm upgrade --install --namespace monitoring --create-namespace prometheus prometheus-community/prometheus --values <(
ingress:
  enabled: true
  hosts:
    - prometheus
)
helm upgrade --install --namespace scaling --create-namespace keda kedacore/keda --set prometheus.enabled=true
helm upgrade --install --namespace nextcloud --create-namespace nextcloud nextcloud/nextcloud \
  --set ingress.enabled=true \
  --set metrics.enabled=true \
  --set nextcloud.host=nextcloud \
  --set nextcloud.password=qwerty \
  --set-string service.port=80

kubectl patch service --namespace monitoring prometheus-server --patch '{
  "spec": {
    "type": "NodePort"
  }
}'
kubectl patch deployments.apps --namespace kube-system ingress-nginx-controller --patch '{
  "spec": {
    "template": {
      "metadata": {
        "annotations": {
          "prometheus.io/port": "10254",
          "prometheus.io/scrape": "true"
        }
      }
    }
  }
}'
# minikube service --namespace monitoring prometheus-server

# kubectl patch service --namespace monitoring grafana --patch '{
#   "spec": {
#     "type": "NodePort"
#   }
# }'
# curl "$(minikube service --namespace monitoring grafana --url)/api/datasources" --request POST --user admin:qwerty --header "Content-Type: application/json" --data '{
#   "name": "Prometheus",
#   "type": "prometheus",
#   "access": "proxy",
#   "url": "http://prometheus-server"
# }'

# echo "$(minikube ip)  nextcloud" | sudo tee -a /etc/hosts
# minikube service --namespace nextcloud nextcloud

kubectl apply --filename - <<EOF
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
  pollingInterval: 5
  advanced:
    restoreToOriginalReplicaCount: true
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus-server.monitoring
      metricName: nginx_ingress_controller_requests
      query: sum(rate(nginx_ingress_controller_requests{ingress="grafana"}[2m]))
      threshold: '1000'
EOF

ab -n 100000 -c 10 http://grafana/







------


#!/usr/bin/env bash

## tested on macosx using minikube 1.17.0 and k8s v1.20.2 on Docker 20.10.2

set -ex

# minikube start --cpus 4 --memory 4GiB --vm
# minikube addons enable ingress
# minikube addons enable metrics-server

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

cat > /tmp/values.demo.grafana.yaml <<EOF
adminPassword: qwerty
ingress:
  enabled: true
  hosts:
    - grafana
EOF

# echo "$(minikube ip)  grafana prometheus" | sudo tee -a /etc/hosts

helm upgrade --install --namespace monitoring --create-namespace prometheus prometheus-community/prometheus
helm upgrade --install --namespace monitoring --create-namespace grafana grafana/grafana --values /tmp/values.demo.grafana.yaml
helm upgrade --install --namespace scaling --create-namespace keda kedacore/keda

kubectl patch service --namespace monitoring prometheus-server --patch '{
  "spec": {
    "type": "NodePort"
  }
}'
minikube service --namespace monitoring prometheus-server

kubectl patch deployments.apps --namespace kube-system ingress-nginx-controller --patch '{
  "spec": {
    "template": {
      "metadata": {
        "annotations": {
          "prometheus.io/port": "10254",
          "prometheus.io/scrape": "true"
        }
      }
    }
  }
}'

curl "http://grafana/api/datasources" --request POST --user admin:qwerty --header "Content-Type: application/json" --data '{
  "name": "Prometheus",
  "type": "prometheus",
  "access": "proxy",
  "url": "http://prometheus-server"
}'
curl "https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/grafana/dashboards/nginx.json" | pbcopy
open http://grafana/
# import a dashboard pasting the clipboard's content

kubectl apply --filename - <<EOF
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
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus-server.monitoring
      metricName: nginx_ingress_controller_requests
      query: sum(rate(nginx_ingress_controller_requests{ingress="grafana"}[2m]))
      threshold: '10'
EOF

# HPA behavior is available from K8S v1.18.0
# ---
kubectl apply --filename - <<EOF
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

ab -n 750 -c 1 http://grafana/
