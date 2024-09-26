# AWX example

```sh
kubectl kustomize --enable-helm 'operator/' | kubectl apply -f -
kubectl apply -k 'instance/'
kubectl -n 'awx' get secret 'awx-admin-password' -o jsonpath="{.data.password}" | base64 --decode
kubectl get ingress -n 'awx' 'awx-ingress' -o jsonpath='{.status.loadBalancer.ingress[*].hostname}' \
| xargs -I{} open http://{}
```
