# KEDA

The _Kubernetes-based Event Driven Auto-Scaler_ automatically scales workloads in a Kubernetes cluster based on defined
triggers.

KEDA monitors the event source, and feeds that data to the cluster. This allows it to scale the monitored workload
accordingly, both leveraging standard Kubernetes components (e.g. HPA) and extending the existing functionality without
overwriting or duplicating components.

Any Kubernetes cluster **>= 1.16.0** should work.

1. [How KEDA works](#how-keda-works)
1. [Setup](#setup)
   1. [Helm chart](#helm-chart)
   1. [Manual deployment](#manual-deployment)
1. [Usage](#usage)
   1. [ScaledObject](#scaledobject)
   1. [ScaledJobs](#scaledjobs)
   1. [Authentication](#authentication)
1. [External Scalers](#external-scalers)
1. [Troubleshooting](#troubleshooting)
   1. [Access logging and telemetry](#access-logging-and-telemetry)
   1. [Long running executions](#long-running-executions)
   1. [Manually uninstall everything](#manually-uninstall-everything)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## How KEDA works

For details and updated information see KEDA's [concepts] page.

Upon installation, KEDA creates the following custom resources to enable one to map an event source to a Deployment,
StatefulSet, Custom Resource or Job for scaling:

- `scaledobjects.keda.sh`
- `scaledjobs.keda.sh`
- `triggerauthentications.keda.sh`

_ScaledObjects_ represent a mapping between an event source (e.g. Rabbit MQ) and any K8S resource (Deployment,
StatefulSet or Custom) that defines the `/scale` subresource.<br/>
_ScaledJobs_, specifically, represent a mapping between an event source and a Kubernetes Job.

_TriggerAuthentication_ are referenced by ScaledObjects and ScaledJobs when they need to access authentication
configurations or secrets to monitor the event source.

KEDA also creates the following containers:

- `keda-operator`
- `keda-operator-metrics-apiserver`

The _operator_ acts as an agent which activates, regulates and deactivates the scaling of K8S resources defined in a
ScaledObject based on the trigger events.

The _metrics apiserver_ exposes rich event data, like _queue length_ or _stream lag_, to the Horizontal Pod Autoscaler
to drive the scaling actions. It is then up to the resource to consume such events directly from the source.

KEDA offers a wide range of triggers (A.K.A. _scalers_) that can both detect if a resource should be activated or
deactivated and feed custom metrics for a specific event source.<br/>
Refer the full list of scalers [here][scalers].

## Setup

### Helm chart

```sh
# Installation.
helm repo add kedacore https://kedacore.github.io/charts \
 && helm repo update kedacore \
 && helm upgrade -i keda kedacore/keda \
      --namespace keda --create-namespace

# Uninstallation.
helm uninstall keda --namespace keda \
 && kubectl delete namespace keda
```

### Manual deployment

Use the YAML declaration (which includes the CRDs and all the other resources) available on the GitHub releases page:

```sh
# Installation.
kubectl apply -f https://github.com/kedacore/keda/releases/download/v2.0.0/keda-2.0.0.yaml

# Uninstallation.
kubectl delete -f https://github.com/kedacore/keda/releases/download/v2.0.0/keda-2.0.0.yaml
```

One can also use the tools in the repository:

```sh
git clone https://github.com/kedacore/keda
cd keda
VERSION=2.0.0 make deploy    # installation
VERSION=2.0.0 make undeploy  # uninstallation
```

## Usage

One can just add KEDA-specific resources to their workload's manifest.

### ScaledObject

Refer KEDA's [Scaling Deployments, StatefulSets and Custom Resources] page.

ScaledObjects define how KEDA should scale one's workload, and what the triggers (A.K.A. scalers) are.
Refer the full list of scalers [here][scalers].

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: {{ scaledObject.name }}
spec:
  scaleTargetRef:
    apiVersion: {{ targetResource.apiVersion }}    # optional; defaults to 'apps/v1'
    kind:       {{ targetResource.Kind }}          # optional; defaults to 'Deployment'
    name:       {{ targetResource.Name }}          # mandatory; the target resource must reside in the same namespace as the ScaledObject
    envSourceContainerName: {{ container.name }}   # optional; defaults to the target's '.spec.template.spec.containers[0]' field
  pollingInterval: 30                              # optional; defaults to 30 seconds
  cooldownPeriod:  300                             # optional; defaults to 300 seconds
  minReplicaCount: 0                               # optional; defaults to 0
  maxReplicaCount: 100                             # optional; defaults to 100
  advanced:                                        # optional
    restoreToOriginalReplicaCount: false           # optional; defaults to false
    horizontalPodAutoscalerConfig:                 # optional
      behavior:                                    # optional; modifies the HPA's default scaling behavior
        scaleDown:
          stabilizationWindowSeconds: 300
          policies:
          - type: Percent
            value: 100
            periodSeconds: 15
  triggers: []                                     # mandatory; list of the triggers (= scalers) which will scale the target resource
```

Custom Resources are scaled the same way as Deployments and StatefulSets, as long as the target Custom Resource defines
the `/scale` [subresource][/scale subresource].

When a ScaledObject is already in place and one first creates the target resource, KEDA will:

1. Immediately scale it to the value of the `minReplicaCount` specification.
1. Scale it up according to the triggers.

The `scaleTargetRef` specification references the resource KEDA will scale and setup an HPA for, based on the triggers
defined in `triggers`.<br/>
The resource referenced by `name` (and `apiVersion` and `kind`) must reside in the same namespace as the ScaledObject.

`envSourceContainerName` specifies the name of the container inside the target resource from which KEDA will retrieve
the environment properties holding secrets etc.<br/>
If not defined, KEDA will try to retrieve them from the **first** Container in the resource's definition.

`pollingInterval` is the interval to check each trigger on.<br/>
I.E., in a _queue_ scenario, KEDA will check the `queueLength` every `pollingInterval` seconds, and scale the referenced
resource up or down accordingly.

`cooldownPeriod` sets how much time to wait after the last trigger reported active, before scaling the resource back to
`minReplicaCount`.<br/>
This only applies after a trigger occurs **and** when scaling down to a `minReplicaCount` value of 0. Scaling from 1 to
N replicas is handled by the Kubernetes Horizontal Pod Autoscaler.

`minReplicaCount` is the minimum amount of replicas KEDA will scale the resource down to. If a non default value (>0)
is used, it will **not** be enforced (meaning that one can _manually_ scale the resource to 0 and KEDA will **not**
scale it back up). However, KEDA will respect the value set there when scaling the resource afterwards.

`maxReplicaCount` sets the maximum amount of replicas for the resource.<br/>
This setting is passed to the HPA definition that KEDA will create for the target.

`restoreToOriginalReplicaCount` specifies whether the target resource should be scaled back to original replicas count
after the ScaledObject is deleted.<br/>
The default behavior is to keep the replica count at the number it is set to at the moment of the ScaledObject's
deletion.

The `horizontalPodAutoscalerConfig.behavior` field allows the HPA's scaling behavior to be configured by feeding the
values from this section directly to the HPA's behavior field.

Example:

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: nextcloud
  namespace: nextcloud
spec:
  scaleTargetRef:
    name: nextcloud
  minReplicaCount: 1
  advanced:
    restoreToOriginalReplicaCount: true
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus-server.monitoring:9090
      metricName: http_requests_total
      query: sum(rate(http_requests_total{deployment="nextcloud"}[2m]))
      threshold: '10'
```

### ScaledJobs

Refer KEDA's [Scaling Jobs] page.

ScaledJobs define how KEDA should scale a Job and what the triggers (_scalers_) are.<br/>
Refer the full list of scalers [here][scalers].

Instead of scaling up the number of replicas, KEDA will schedule a single Job for each detected event.<br/>
For this, a ScaledJob is primarily used for long running executions or small tasks being able to run in parallel in
massive spikes like processing queue messages.

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledJob
metadata:
  name: {{ scaledJob.name }}
spec:
  jobTargetRef:
    parallelism: 1                               # [max number of desired pods](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/#controlling-parallelism)
    completions: 1                               # [desired number of successfully finished pods](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/#controlling-parallelism)
    activeDeadlineSeconds: 600                   # specifies the duration in seconds relative to the startTime field that the job may be active before the system tries to terminate it; its value must be a positive integer
    backoffLimit: 6                              # specifies the number of retries before marking this job failed; defaults to 6
    template:                                    # describes the [job template](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/)
  pollingInterval: 30                            # optional; defaults to 30 seconds
  successfulJobsHistoryLimit: 5                  # optional; how many completed jobs should be kept as history; defaults to 100
  failedJobsHistoryLimit: 5                      # optional; how many failed jobs should be kept as history; defaults to 100
  envSourceContainerName: {{ container.name }}   # optional; defaults to the target's '.spec.JobTargetRef.template.spec.containers[0]' field
  maxReplicaCount: 100                           # optional; defaults to 100
  scalingStrategy:
    strategy: "custom"                           # optional; which Scaling Strategy to use; defaults to 'default'
    customScalingQueueLengthDeduction: 1         # optional; a parameter to optimize custom ScalingStrategy.
    customScalingRunningJobPercentage: "0.5"     # optional; a parameter to optimize custom ScalingStrategy.
  triggers: []                                   # list of the triggers (= scalers) which will spawn jobs
```

`pollingInterval` is the interval in seconds KEDA will check each trigger on.

`successfulJobsHistoryLimit` and `failedJobsHistoryLimit` specify how many _completed_ and _failed_ jobs should be kept,
similarly to Jobs History Limits; it allows to learn what the outcome of the jobs are.<br/>
The actual number of jobs **could exceed** that limit in a short time, but it is going to resolve in the cleanup period.
Currently, the cleanup period is the same as the Polling interval.

`envSourceContainerName` specifies the name of container in the target Job from which KEDA will retrieve the environment
properties holding secrets etc.<br/>
If not defined, KEDA will try to retrieve them from the **first** Container in the target resource's definition.

`maxReplicaCount` is the maximum number of Job Pods that can be in existence within a single polling period.<br/>
Should there be Jobs already running, others will be created only up to this numbers (or none if their number exceeds
this value).

`scalingStrategy` is one from _default_, _custom_, or _accurate_.<br/>
Refer [this PR](https://github.com/kedacore/keda/pull/1227).

Example:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: rabbitmq-consumer
data:
  RabbitMqHost: <omitted>
---
apiVersion: keda.sh/v1alpha1
kind: ScaledJob
metadata:
  name: rabbitmq-consumer
  namespace: default
spec:
  jobTargetRef:
    template:
      spec:
        containers:
        - name: rabbitmq-client
          image: tsuyoshiushio/rabbitmq-client:dev3
          imagePullPolicy: Always
          command: ["receive",  "amqp://user:PASSWORD@rabbitmq.default.svc.cluster.local:5672", "job"]
          envFrom:
            - secretRef:
                name: rabbitmq-consumer
        restartPolicy: Never
    backoffLimit: 4
  pollingInterval: 10
  maxReplicaCount: 30
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 2
  scalingStrategy:
    strategy: "custom"
    customScalingQueueLengthDeduction: 1
    customScalingRunningJobPercentage: "0.5"
  triggers:
  - type: rabbitmq
    metadata:
      queueName: hello
      host: RabbitMqHost
      queueLength  : '5'
```

### Authentication

For details and updated information see KEDA's [Authentication] page.

## External Scalers

For details and updated information see KEDA's [External Scalers] page.

## Troubleshooting

### Access logging and telemetry

Use the logs for the keda operator or apiserver:

```sh
kubectl logs --namespace keda keda-operator-8488964969-sqbxq
kubectl logs --namespace keda keda-operator-metrics-apiserver-5b488bc7f6-8vbpl
```

### Long running executions

There is, at the moment of writing, no way to control which of the replicas is terminated when a HPA decides to scale
down a resource. This means that the HPA may attempt to terminate a replica that is deep into processing a long
execution (e.g. a 3 hour queue message).

To handle this:

- Leverage `lifecycle hooks` to delay termination.
- Use a Job to do the processing, instead of a Deployment/StatefulSet/Custom Resource.

### Manually uninstall everything

Just run the following:

```sh
kubectl delete -f https://raw.githubusercontent.com/kedacore/keda/main/config/crd/bases/keda.sh_scaledobjects.yaml
kubectl delete -f https://raw.githubusercontent.com/kedacore/keda/main/config/crd/bases/keda.sh_scaledjobs.yaml
kubectl delete -f https://raw.githubusercontent.com/kedacore/keda/main/config/crd/bases/keda.sh_triggerauthentications.yaml
```

Then, delete the namespace.

## Further readings

- KEDA's [concepts]
- [Authentication]
- [External Scalers]
- [Scaling Deployments, StatefulSets and Custom Resources]
- [Scaling Jobs]
- The complete [scalers] list
- The project's [website]
- The project's [FAQ]s
- [Kubernetes]

### Sources

- [KEDA: Event Driven and Serverless Containers in Kubernetes] by Jeff Hollan, Microsoft
- The `/scale` [subresource][/scale subresource]
- The [ScaledObject specification]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[kubernetes]: README.md

<!-- Upstream -->
[authentication]: https://keda.sh/docs/2.0/concepts/authentication/
[concepts]: https://keda.sh/docs/2.0/concepts/
[external scalers]: https://keda.sh/docs/2.0/concepts/external-scalers/
[faq]: https://keda.sh/docs/2.0/faq/
[scalers]: https://keda.sh/docs/2.0/scalers/
[scaling deployments, statefulsets and custom resources]: https://keda.sh/docs/2.0/concepts/scaling-deployments/
[scaling jobs]: https://keda.sh/docs/2.0/concepts/scaling-jobs/
[website]: https://keda.sh/

<!-- Others -->
[keda: event driven and serverless containers in kubernetes]: https://www.youtube.com/watch?v=ZK2SS_GXF-g
[scaledobject specification]: https://github.com/kedacore/keda/blob/v2.0.0/api/v1alpha1/scaledobject_types.go
[/scale subresource]: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#scale-subresource
