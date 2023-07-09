# Google cloud platform CLI

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Login.
gcloud auth login
gcloud auth login account

# Set applications.
gcloud auth application-default login
gcloud auth application-default login --no-launch-browser

# Activate a service account.
gcloud auth activate-service-account \
  serviceaccount@gcpproject.iam.gserviceaccount.com \
  --key-file /tmp/sa.credentials.json

# Configure the CLI.
gcloud config set account serviceaccount@gcpproject.iam.gserviceaccount.com
gcloud config set project project-id
gcloud config set compute/region europe-west1

# List current settings.
gcloud config list
gcloud config list --configuration profile

# Create a new profile.
gcloud config configurations create new-active-profile
gcloud config configurations create --no-activate new-inactive-profile

# List available profiles.
gcloud config configurations list

# Switch to a different configuration.
gcloud config configurations activate old-profile

# SSH into a compute instance.
gcloud compute ssh --zone zone instance --project project
gcloud beta compute ssh --zone zone instance --project project

# Show operations.
# Filters are suggested.
gcloud container operations list --filter="NOT status:DONE"
gcloud container operations list \
  --filter="name:operation-1513320920760-9c26cff5 AND status:RUNNING"
gcloud compute operations list --filter="region:europe-west4 AND -status:DONE"
gcloud compute operations list \
  --filter="region:(europe-west4 us-east2)" \
  --filter="status!=DONE"

# Use a specific service account for an operation.
# The service account must have been activated.
gcloud config set account serviceaccount@gcpproject.iam.gserviceaccount.com \
&& gcloud auth application-default login --no-launch-browser \
&& gcloud compute instances list

# Logout.
gcloud auth revoke --all
gcloud auth revoke account
```

## Further readings

- [Gcloud cheat-sheet]
- [Kubectl cluster access]
- [Gcloud config configurations]

## Sources

All the references in the [further readings] section, plus the following:

- [How to run gcloud command line using a service account]
- [How to change the active configuration profile in gcloud]

<!--
  References
  -->

<!-- Upstream -->
[gcloud cheat-sheet]: https://cloud.google.com/sdk/gcloud/reference/cheat-sheet
[gcloud config configurations]: https://cloud.google.com/sdk/gcloud/reference/config/configurations
[kubectl cluster access]: https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Others -->
[how to change the active configuration profile in gcloud]: https://stackoverflow.com/questions/35744901/how-to-change-the-active-configuration-profile-in-gcloud#35750001
[how to run gcloud command line using a service account]: https://pnatraj.medium.com/how-to-run-gcloud-command-line-using-a-service-account-f39043d515b9
