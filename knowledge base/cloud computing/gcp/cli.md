# The `gcloud` utility

CLI for the Google Cloud Platform.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Login.
gcloud auth login
gcloud … --brief
gcloud … "email@example.com"

# Print access tokens.
gcloud auth print-access-token
gcloud … "email@example.com"

# List all credentialed accounts.
# Also identify the current active account.
gcloud auth list

# Revoke credentials.
# A.K.A. logout.
gcloud auth revoke "email@example.com"
gcloud auth revoke --all


# Setup applications.
gcloud auth application-default login
gcloud … --no-launch-browser

# Activate service accounts.
gcloud auth activate-service-account \
  "serviceaccount@gcpproject.iam.gserviceaccount.com" \
  --key-file "/path/to/sa.credentials.json"


# Configure the CLI.
gcloud config set 'account' "serviceaccount@gcpproject.iam.gserviceaccount.com"
gcloud … 'project' "project_id"
gcloud … 'compute/region' "europe-west1"
gcloud config unset 'project'

# List current settings.
gcloud config list
gcloud … --configuration "profile_name"


# Create new profiles.
gcloud config configurations create "new_active_profile"
gcloud … --no-activate "new_inactive_profile"

# List available profiles.
gcloud config configurations list

# Switch to different configurations.
gcloud config configurations activate "old_profile"


# List all project the current user has access to.
gcloud projects list --sort-by='projectId'

# Delete projects.
gcloud projects delete "project_name"

# Undo delete project.
# Available for a limited period of time only.
gcloud projects undelete "project_name"

# Add the 'pubsub.admin' IAM Role to the 'awesome-sa' service account in the
# 'gcp-project' project.
gcloud projects add-iam-policy-binding "project_name" \
  --member "serviceAccount:awesome-sa@gcp-project.iam.gserviceaccount.com" \
  --role 'roles/pubsub.admin'

# Remove the 'pubsub.subscriber' IAM Role from the 'awesome-sa' service account
# in the 'gcpproject' project.
gcloud projects remove-iam-policy-binding "project_name" \
  --member="serviceAccount:awesome-sa@gcp-project.iam.gserviceaccount.com" \
  --role='roles/pubsub.subscriber'


# SSH into compute instances.
# Includes GKE clusters' compute instances.
gcloud compute ssh "instance-name" --zone "zone_name"
gcloud … --zone "zone_name" "instance_name" --project "project_name"


# Get all Kubernetes versions available for use in GKE clusters.
gcloud container get-server-config --format 'yaml(validNodeVersions)'
gcloud … --format 'yaml(validMasterVersions)' --zone "compute_zone_name"
gcloud … --flatten='channels' --filter='channels.channel=RAPID' \
  --format='yaml(channels.channel,channels.validVersions)'

# Generate 'kubeconfig' entries for GKE clusters.
gcloud container clusters get-credentials "cluster_name"
gcloud … "cluster_name" --region "region_name"


# Show operations.
# Filters are suggested.
gcloud container operations list --filter='NOT status:DONE'
gcloud compute … --filter='region:europe-west4 AND -status:DONE'
gcloud container … \
  --filter='name:operation-1513320920760-9c26cff5 AND status:RUNNING'
gcloud compute … \
  --filter='region:(europe-west4 us-east2)' \
  --filter='status!=DONE'


# Connect to cloud SQL instances.
gcloud sql connect "instance_name" --user="root" --quiet


# Use specific service accounts for an operation.
# The service account must have been already activated.
gcloud config set account "serviceaccount@gcpproject.iam.gserviceaccount.com" \
&& gcloud auth application-default login --no-launch-browser \
&& gcloud compute instances list
```

## Further readings

- [Creating and managing projects]
- [Install kubectl and configure cluster access]
- [`gcloud config configurations`][gcloud config configurations]

## Sources

All the references in the [further readings] section, plus the following:

- [Reference]
- [Cheat-sheet]
- [How to run gcloud command line using a service account]
- [How to change the active configuration profile in gcloud]

<!--
  References
  -->

<!-- Upstream -->
[cheat-sheet]: https://cloud.google.com/sdk/gcloud/reference/cheat-sheet
[creating and managing projects]: https://cloud.google.com/resource-manager/docs/creating-managing-projects
[gcloud config configurations]: https://cloud.google.com/sdk/gcloud/reference/config/configurations
[install kubectl and configure cluster access]: https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl
[reference]: https://cloud.google.com/sdk/gcloud/reference/

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Others -->
[how to change the active configuration profile in gcloud]: https://stackoverflow.com/questions/35744901/how-to-change-the-active-configuration-profile-in-gcloud#35750001
[how to run gcloud command line using a service account]: https://pnatraj.medium.com/how-to-run-gcloud-command-line-using-a-service-account-f39043d515b9
