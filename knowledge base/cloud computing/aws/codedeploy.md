# AWS CodeDeploy

Deployment service offered by [AWS][amazon web services].

1. [TL;DR](#tldr)
1. [Service role](#service-role)
1. [Flow](#flow)
1. [Deployment](#deployment)
   1. [Deploy to instances](#deploy-to-instances)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Automates application deployments to EC2 and on-premises instances, Lambda functions, or ECS.

Application content can be stored in S3 buckets, or GitHub or Bitbucket repositories.<br/>
No changes are needed to the application itself.

| Component                | Summary                                                                                                                  |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| Application              | Name used as reference to ensure the correct components are chosen during a deployment                                   |
| Compute platform         | Platform on which applications are deployed.<br/>Choices include _EC2/On-Premises_, _AWS Lambda_, and _Amazon ECS_.      |
| Deployment configuration | Set of rules and success/failure conditions used during deployments                                                      |
| Deployment group         | Set of tagged EC2/on-premise instances to deploy to, if used                                                             |
| Deployment type          | How applications are made available to instances in a deployment group.<br/>Choices include _in-place_ and _blue/green_. |
| IAM instance profile     | IAM role for EC2 instances.<br/>It must have the permissions required to access the application code.                    |
| Revision                 | Application versions                                                                                                     |
| Service role             | IAM Role used by CodeDeploy to access AWS resources                                                                      |
| Target revision          | Application revision currently targeted for deployment                                                                   |

<!-- Uncomment if used
<details>
  <summary>Setup</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Service role

CodeDeploy uses an IAM role when acting.<br/>
This _service_ role requires access to the following:

- Read either the tags applied to instances, or their associated EC2 Auto Scaling group names.<br/>
  Needed to identify instances to which it can deploy applications.
- Perform operations on instances, EC2 Auto Scaling groups, and Elastic Load Balancers.
- Publish information to SNS topics.<br/>
  Needed to send notifications when specified deployment or instance events occur.
- Retrieve information about CloudWatch alarms.<br/>
  Needed to set up alarm monitoring for deployments.

## Flow

```mermaid
flowchart LR
  TODO
```

## Deployment

### Deploy to instances

One must set up the instances before CodeDeploy can deploy application revisions to them for the first time.

**Manually** provisioned instances must abide the following:

- The CodeDeploy agent must be present on the instances.
- They must be tagged, if one is using tags to identify instances in a deployment group.<br/>
  CodeDeploy relies on tags to identify and group instances into deployment groups.
- They must be launched with an IAM instance profile attached.<br/>
  The instance profile is required by the CodeDeploy agent to verify the identity of the instance.
- They must be modifiable by the [service role] used by CodeDeploy.

Instances are taken offline during deployments so that the latest application revision can be installed.

Instances are assigned two health status values each: _revision health_ and _instance health_.<br/>
Revision health is based on the application revision currently installed on the instance.<br/>
Instance health is based on whether deployments to the instance have been successful.

CodeDeploy uses the two health status values to schedule deployments to deployment groups' instances in the following
order:

1. Unhealthy instance health.
1. Unknown revision health.
1. Old revision health.
1. Current revision health.

Deployments fail if the number of healthy instances falls below the minimum number specified for the deployment
group.<br/>
For overall deployments to succeed, the following must be true:

- CodeDeploy is able to deploy to each instance in the deployment group.
- Deployment to at least **one** instance must succeed, even if the minimum healthy hosts value is `0`.

When overall deployments succeed, the revision in question is updated and the deployment group's health status values
are updated to reflect the latest deployment.

When overall deployments fail or are stopped:

- Each instance to which CodeDeploy attempted to deploy the application revision has its instance health set to either
  `healthy` or `unhealthy`, depending on whether the deployment attempt for that instance succeeded or failed.
- Each instance to which CodeDeploy did **not** attempt to deploy the application revision retains its current instance
  health value.
- The deployment group's revision remains the same.

## Further readings

- [Documentation]
- [Amazon Web Services]

### Sources

- [Instance health]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[service role]: #service-role

<!-- Knowledge base -->
[amazon web services]: README.md

<!-- Files -->
<!-- Upstream -->
[documentation]: https://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html
[instance health]: https://docs.aws.amazon.com/codedeploy/latest/userguide/instances-health.html

<!-- Others -->
