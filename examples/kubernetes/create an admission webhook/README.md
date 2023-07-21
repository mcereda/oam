# Create an admission webhook

The example below will create a webhook which acts as both a `ValidatingAdmissionWebhook` and a `MutatingAdmissionWebhook`, but a real world one can act as only one of them. Or more. Your choice.<br/>
The procedure is executed in a `minikube` cluster, and will use a self signed certificate for the webhook connection.

> Be aware of the pros and cons of an `AdmissionWebhook` before deploying one:
>
> - when deploying the resources it validates it will **need to be up and running**, or those resources will be rejected
> - it will need to manage exception to avoid downtime

## Table of content <!-- omit in toc -->

1. [Concepts reminder](#concepts-reminder)
1. [Check the webhook controllers are enabled](#check-the-webhook-controllers-are-enabled)
1. [Write the webhook](#write-the-webhook)
   1. [Create a certificate](#create-a-certificate)
1. [Configure the webhook](#configure-the-webhook)
1. [Troubleshooting](#troubleshooting)
   1. [I cannot deploy the resources because the webhook cannot be reached](#i-cannot-deploy-the-resources-because-the-webhook-cannot-be-reached)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Concepts reminder

There are 2 special admission controllers in the list included in the Kubernetes `apiserver`:

- `ValidatingAdmissionWebhook`s, which can reject a request but cannot modify the object they are receiving in the admission request, and
- `MutatingAdmissionWebhook`s, which can modify objects by creating a patch that will be sent back in the admission response

These send admission requests to external HTTP callbacks and receive admission responses. If these two controllers are enabled, a Kubernetes administrator can create and configure an admission webhook in the cluster.

To do this:

1. [check if the admission webhook controllers are enabled](#check-the-webhook-controllers-are-enabled) in the cluster, and configure them if needed
1. [write the HTTP callback](#write-the-webhook) that will handle an admission requests; this can be a simple HTTP server that's deployed to the cluster, or even a serverless function just like in [Kelsey's validating webhook demo]
1. [configure the webhook](#configure-the-webhook) through the `ValidatingWebhookConfiguration` and/or `MutatingWebhookConfiguration` resources

## Check the webhook controllers are enabled

Check:

1. if the `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` admission controllers are listed in the correct order in the `admission-control` flag of `kube-apiserver`:

   ```sh
   $ kubectl get pods --namespace 'kube-system' 'kube-apiserver-minikube' -o 'yaml' \
     | yq -y '.spec.containers[]
         | select(.name == "kube-apiserver")
         | .command' \
       - \
     | grep -e '--enable-admission-plugins' \
     | tr ',' '\n' \
     | grep 'AdmissionWebhook'
   MutatingAdmissionWebhook
   ValidatingAdmissionWebhook
   ```

1. if the admission registration API is enabled in your cluster by running the following:

   ```sh
   $ kubectl api-versions | grep 'admissionregistration.k8s.io'
   admissionregistration.k8s.io/v1
   admissionregistration.k8s.io/v1beta1
   ```

## Write the webhook

Every language is fine as long as the webhook:

- accepts an [admission request];
- spits out an [admission response];
- uses a certificate to secure the connection, as all admission webhooks need to be on SSL; a self-signed certificate will be more than fine for testing

Example: [webhook.py]

After the webhook's creation:

1. create a containerized image of the webhook and save it to the registry
   Dockerfile: [Dockerfile]

   ```sh
   $ docker build -t webhook .

   # on minikube
   # will also need imagePullPolicy=Never in the container's spec
   $ minikube cache add webhook
   ```

1. (if needed, see [below](#create-a-certificate)) to generate the self signed CA, a `CertificateSigningRequest` and the certificate, then create a `Secret` based on this certificate;
1. create a `Deployment` that will use the image created above; the service **must** be secured via SSL, so mount the secret created from the previous step as volumes in it

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: webhook
     namespace: test
     labels:
       app: webhook
   spec:
     selector:
       matchLabels:
         app: webhook
     template:
       metadata:
         namespace: test
         labels:
           app: webhook
       spec:
         containers:
         - name: webhook
           image: webhook
           imagePullPolicy: Never  # needed by minikube
           ports:
           - containerPort: 8443
           volumeMounts:
           - mountPath: /cert
             name: cert
         volumes:
         - name: cert
           secret:
             secretName: webhook
   ```

1. create a `Service` pointing to the correct ports in same namespace as the `Deployment`

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: webhook
     namespace: test
   spec:
     selector:
       app: webhook
     ports:
       - protocol: TCP
         port: 443
         targetPort: 8443
   ```

### Create a certificate

For testing purposes, let's just reuse the [script][certificate script] originally written by the Istio team to generate a certificate signing request:

```sh
cd /tmp
curl --continue-at - --remote-name https://raw.githubusercontent.com/istio/istio/release-0.7/install/kubernetes/webhook-create-signed-cert.sh
bash /tmp/webhook-create-signed-cert.sh --service webhook --namespace test --secret webhook
cd -
```

## Configure the webhook

Create a `ValidatingWebhookConfiguration` to register the service for validation upon pod creation:

```yaml
apiVersion: admissionregistration.k8s.io/v1beta1
kind: ValidatingWebhookConfiguration
metadata:
  name: validating-webhook
  namespace: test
webhooks:
  - name: webhook.example.com
    failurePolicy: Fail
    clientConfig:
      service:
        name: webhook
        namespace: test
        path: /validate
    rules:
      - apiGroups: [""]
        resources:
          - "pods"
        apiVersions:
          - "*"
        operations:
          - CREATE
```

At the same way, create a `MutatingWebhookConfiguration` to register the service for mutation upon pod creation:

```yaml
apiVersion: admissionregistration.k8s.io/v1beta1
kind: MutatingWebhookConfiguration
metadata:
  name: mutating-webhook
  namespace: test
  labels:
    component: mutating-controller
webhooks:
  - name: webhook.example.com
    failurePolicy: Fail
    clientConfig:
      service:
        name: webhook
        namespace: test
        path: /mutate
    rules:
      - apiGroups: [""]
        resources:
          - "pods"
        apiVersions:
          - "*"
        operations:
          - CREATE
```

## Troubleshooting

### I cannot deploy the resources because the webhook cannot be reached

**Solution:** remove the AdmissionWebhook and the Service forwarding to it, then reapply its definition

## Further readings

- [Admission request]
- [Admission response]
- This example's [Dockerfile]
- This example's [webhook source][webhook.py]
- This example's [resources]
- This example's [cert script]
- [Extensible admission controllers]

## Sources

All the references in the [further readings] section, plus the following:

- [Creating your own admission controller]
- [Diving into Kubernetes mutatingAdmissionWebhook]
- [how to write validating and mutating admission controller webhooks in python for kubernetes]
- [building a kubernetes mutating admission webhook]
- [K8S admission webhooks]
- [How to Master Admission Webhooks In Kubernetes]
- [openshift's generic admission server]
- [kelsey's validating webhook demo]
- [morvencao's kube-mutating-webhook-tutorial]
- [writing a very basic kubernetes mutating admission webhook]
- Istio's [script][certificate script] to generate a certificate signing request

<!--
  References
  -->

<!-- Upstream -->
[admission request]: https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#request
[admission response]: https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#response
[cert script]: create-signed-cert.sh
[certificate script]: https://raw.githubusercontent.com/istio/istio/release-0.7/install/kubernetes/webhook-create-signed-cert.sh
[dockerfile]: Dockerfile
[extensible admission controllers]: https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/
[resources]: resources.yaml
[webhook.py]: webhook.py

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Others -->
[building a kubernetes mutating admission webhook]: https://didil.medium.com/building-a-kubernetes-mutating-admission-webhook-7e48729523ed
[creating your own admission controller]: https://docs.giantswarm.io/guides/creating-your-own-admission-controller/
[diving into kubernetes mutatingadmissionwebhook]: https://medium.com/ibm-cloud/diving-into-kubernetes-mutatingadmissionwebhook-6ef3c5695f74
[how to master admission webhooks in kubernetes]: https://digizoo.com.au/1376/mastering-admission-webhooks-in-kubernetes-gke-part-1/
[how to write validating and mutating admission controller webhooks in python for kubernetes]: https://medium.com/analytics-vidhya/how-to-write-validating-and-mutating-admission-controller-webhooks-in-python-for-kubernetes-1e27862cb798
[k8s admission webhooks]: https://banzaicloud.com/blog/k8s-admission-webhooks/
[kelsey's validating webhook demo]: https://github.com/kelseyhightower/denyenv-validating-admission-webhook
[morvencao's kube-mutating-webhook-tutorial]: https://github.com/morvencao/kube-mutating-webhook-tutorial
[openshift's generic admission server]: https://github.com/openshift/generic-admission-server
[writing a very basic kubernetes mutating admission webhook]: https://medium.com/ovni/writing-a-very-basic-kubernetes-mutating-admission-webhook-398dbbcb63ec
