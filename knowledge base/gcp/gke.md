# Google Kubernetes Engine

Managed Kubernetes solution offered by the Google Cloud Platform.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Gotchas](#gotchas)
1. [SSH into GKE clusters' compute instances](#ssh-into-gke-clusters-compute-instances)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Generate 'kubeconfig' entries for gke clusters.
gcloud container clusters get-credentials 'cluster-name'
gcloud container clusters get-credentials 'cluster-name' --region 'region'

# Get all Kubernetes versions available for use in gke clusters.
gcloud container get-server-config --format "yaml(validNodeVersions)"
gcloud container get-server-config --format "yaml(validMasterVersions)" --zone 'compute-zone'
gcloud container get-server-config --flatten="channels" --filter="channels.channel=RAPID" --format="yaml(channels.channel,channels.validVersions)"

# SSH into gke clusters' compute instances.
gcloud compute ssh 'instance-name' --zone 'zone'
```

## Gotchas

- When creating admission webhooks, either make sure to expose your webhook service and deployments on port 443 or poke a hole in the firewall for the port they are listening to.<br/>
  By default, firewall rules restrict the cluster's masters communication to nodes only on ports 443 (HTTPS) and 10250 (kubelet). Additionally, GKE enables the `enable-aggregator-routing` option by default, which makes the master to bypass the service and communicate straight to pods.

## SSH into GKE clusters' compute instances

Use the same procedure to connect to any other compute instance:

```sh
$ gcloud compute ssh 'gke-euwe4-my-instance'
WARNING: The private SSH key file for gcloud does not exist.
WARNING: The public SSH key file for gcloud does not exist.
WARNING: You do not have an SSH key for gcloud.
WARNING: SSH keygen will be executed to generate a key.
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /Users/you/.ssh/google_compute_engine.
Your public key has been saved in /Users/you/.ssh/google_compute_engine.pub.
The key fingerprint is:
SHA256:cbYuJKZROlbzX2wuzzN4zd3OGu6m7CupYKJHdiYOxVw you@machine
The key's randomart image is:
+---[RSA 3072]----+
|                 |
|      E          |
|   o .+ . o      |
|    ++ o + o     |
|   .= o S . +    |
|  ..+=oo o +     |
|   =o+o . +o.o...|
|   .oo . .+=+.+oo|
|  ..    .. +BB+oo|
+----[SHA256]-----+
No zone specified. Using zone [europe-west4-c] for instance: [gke-euwe4-my-instance].
External IP address was not found; defaulting to using IAP tunneling.
Updating project ssh metadata...⠹Updated [https://www.googleapis.com/compute/v1/projects/gcp-project].
Updating project ssh metadata...done.
Waiting for SSH key to propagate.
Warning: Permanently added 'compute.4401449885042934396' (ED25519) to the list of known hosts.
Enter passphrase for key '/Users/you/.ssh/google_compute_engine':
Enter passphrase for key '/Users/you/.ssh/google_compute_engine':

Welcome to Kubernetes v1.16.15-gke.6000!

You can find documentation for Kubernetes at:
  http://docs.kubernetes.io/

The source for this release can be found at:
  /home/kubernetes/kubernetes-src.tar.gz
Or you can download it at:
  https://storage.googleapis.com/kubernetes-release-gke/release/v1.16.15-gke.6000/kubernetes-src.tar.gz

It is based on the Kubernetes source at:
  https://github.com/kubernetes/kubernetes/tree/v1.16.15-gke.6000

For Kubernetes copyright and licensing information, see:
  /home/kubernetes/LICENSES

[instance]$
```

## Further readings

- [How to Master Admission Webhooks In Kubernetes]
- [Kubectl cluster access]

## Sources

All the references in the [further readings] section, plus the following:

- [Connect to a compute instance]
- [Preparing a Google Kubernetes Engine environment for production]

<!-- project's references -->
[connect to a compute instance]: https://cloud.google.com/compute/docs/instances/connecting-to-instance
[kubectl cluster access]: https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl
[preparing a google kubernetes engine environment for production]: https://cloud.google.com/solutions/prep-kubernetes-engine-for-prod

<!-- internal references -->
[further readings]: #further-readings

<!-- external references -->
[how to master admission webhooks in kubernetes]: https://digizoo.com.au/1376/mastering-admission-webhooks-in-kubernetes-gke-part-1/
