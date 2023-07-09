# The `gcloud` utility

CLI for the Google Cloud Platform.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# List all project the current user has access to.
gcloud projects list --sort-by=projectId

# Delete projects.
gcloud projects delete 'project-name'

# Undo delete project operations.
# Available for a limited period of time.
gcloud projects undelete 'project-name'

# Add the pubsub admin role to the 'awesome-sa' service account in the
# 'gcp-project' project.
gcloud projects add-iam-policy-binding 'gcp-project' \
  --member "serviceAccount:awesome-sa@gcp-project.iam.gserviceaccount.com" \
  --role "roles/pubsub.admin"

# Remove the pubsub subscriber role from the 'awesome-sa' service account in the gcpproject project
gcloud projects remove-iam-policy-binding 'gcp-project' \
  --member="serviceAccount:awesome-sa@gcp-project.iam.gserviceaccount.com" \
  --role="roles/pubsub.subscriber"

# Get all Kubernetes versions available for use in gke clusters.
gcloud container get-server-config --format "yaml(validNodeVersions)"
gcloud container get-server-config --format "yaml(validMasterVersions)" --zone 'compute-zone'
gcloud container get-server-config --flatten="channels" --filter="channels.channel=RAPID" --format="yaml(channels.channel,channels.validVersions)"

# Generate 'kubeconfig' entries for gke clusters.
gcloud container clusters get-credentials 'cluster-name'
gcloud container clusters get-credentials 'cluster-name' --region 'region'

# SSH into compute instances.
# Includes gke clusters' compute instances.
gcloud compute ssh 'instance-name' --zone 'zone'

# Connect to cloud SQL instances.
gcloud sql connect 'instance-name' --user='root' --quiet
```

## Further readings

- [Creating and managing projects]

## Sources

All the references in the [further readings] section, plus the following:

- [`gcloud projects`][gcloud projects]

<!--
  References
  -->

<!-- Upstream -->
[creating and managing projects]: https://cloud.google.com/resource-manager/docs/creating-managing-projects
[gcloud projects]: https://cloud.google.com/sdk/gcloud/reference/projects

<!-- In-article sections -->
[further readings]: #further-readings
