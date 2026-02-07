# Elastic Compute Cloud

1. [TL;DR](#tldr)
1. [Burstable instances](#burstable-instances)
1. [Spot instances](#spot-instances)
1. [Disks](#disks)
   1. [Ephemeral storage](#ephemeral-storage)
1. [Monitoring](#monitoring)
   1. [Metrics](#metrics)
1. [Auto scaling](#auto-scaling)
   1. [Lifecycle hooks](#lifecycle-hooks)
1. [Image customization](#image-customization)
1. [Automatic recovery](#automatic-recovery)
1. [Cost-saving measures](#cost-saving-measures)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

The API for EC2 are [**eventually** consistent][Eventual consistency in the Amazon EC2 API].

EC2 instances are billed by the second, with a minimum of 60s,
[since 2017-10-02][announcing amazon ec2 per second billing].

Use an IAM Instance Profile to allow an EC2 instance to use an IAM role.

`T` instances launch as `unlimited` by default. Launch them in `standard` mode to avoid paying for surplus credits.

The instance type [_can_ be changed][change the instance type]. The procedure depends on the root volume, and **does**
require downtime.

When using spot instances, prefer instrumenting the application to be aware of [termination notifications].

Clone EC2 instances by:

1. Creating an AMI from the original instance.
   Mind the default behaviour of the AMI creator is to **shutdown** the instance, take a snapshot, and boot it again
   [to guarantee the image's filesystem integrity][create an ami from an amazon ec2 instance].
1. Using that AMI to launch clones identical to the original.

Consider using specialized AMIs for specialized purposes.<br/>
E.g., [using AL2023 based Amazon ECS AMIs to host containerized workloads].

<details>
  <summary>Real world use cases</summary>

```sh
# Get the IDs of running nginx instances in 'dev'.
aws ec2 describe-instances --output 'text' \
  --query 'Reservations[].Instances[].InstanceId[]'
  --filters \
    'Name=instance-state-name,Values=running' \
    'Name=tag:env,Values=dev' \
    'Name=tag:app,Values=nginx' \

# Start SSM sessions to specific machines.
aws ec2 describe-instances --output text \
  --query 'Reservations[].Instances[].InstanceId' \
  --filters \
    'Name=app,Values=mysql' \
    'Name=instance-state-name,Values=running' \
| xargs -ot aws ssm start-session --target

# Show images details.
aws ec2 describe-images --image-ids 'ami-8b8c57f8'
aws ec2 describe-images --filters \
  'Name=name,Values=["al2023-ami-minimal-*"]' \
  'Name=owner-alias,Values=["amazon"]' \
  'Name=architecture,Values=["arm64","x86_64"]' \
  'Name=block-device-mapping.volume-type,Values=["gp3"]'

# Describe security groups.
aws ec2 describe-security-groups --group-names 'pulumi-workshop'

# Delete security groups.
aws ec2 delete-security-group --group-name 'pulumi-workshop'
aws ec2 delete-security-group --group-id 'sg-0773aa724d0c2dd51'

# Query the onboard IMDSv1 metadata server.
curl 'http://instance-data/latest/meta-data/instance-id'
curl 'http://169.254.169.254/latest/meta-data/instance-type'
curl 'http://[fd00:ec2::254]/latest/meta-data/local-ipv4'

# Query the onboard IMDSv2 metadata server.
TOKEN="$(curl -X 'PUT' 'http://169.254.169.254/latest/api/token' -H 'X-aws-ec2-metadata-token-ttl-seconds: 60')" \
&& curl -H "X-aws-ec2-metadata-token: $TOKEN" 'http://169.254.169.254/latest/meta-data/iam/security-credentials'

# Configure the CloudWatch agent
amazon-cloudwatch-agent-ctl -a 'status'
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a 'set-log-level' -l 'INFO'
amazon-cloudwatch-agent-ctl -a 'fetch-config' -m 'ec2' -s -c 'file:/opt/custom/aws/cloudwatch/agent-config.json'
tail -f '/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log'
```

</details>

## Burstable instances

`T` instances are burstable.

Refer [Burstable performance instances] and [Key concepts and definitions for burstable performance instances].

Traditional EC2 instance types provide fixed CPU resources.<br/>
Burstable performance instances provide a baseline level of CPU utilization, with the ability to burst CPU utilization
above the baseline level.

One only pays for the baseline CPU, plus any additional burst CPU usage over a 24-hour period.

The baseline utilization and ability to burst are governed by **CPU credits**.<br/>
Burstable performance instances continuously earn credits when they stays **below** the CPU baseline, and continuously
spend credits when they bursts above the baseline.<br/>
**Accrued credits** can be used later to burst above baseline CPU utilization.<br/>
Credits can be accrued only up to a point. How high this limit is depends on the instance type.<br/>
When the credits spent are more than credits earned, the instance behavior depends on the credit configuration mode
(_Standard_ or _Unlimited_).

In Standard mode, burstable instances:

- Use the accrued credits to burst above baseline CPU utilization when they are available.
- **Gradually** come down to baseline CPU utilization if there are no accrued credits remaining.
- **Cannot** burst above baseline until they accrue more credits.

In Unlimited mode, burstable instances:

- Use the accrued credits to burst above baseline CPU utilization when they are available.
- Spend surplus credits to continue bursting above baseline if there are no accrued credits remaining.
- Use CPU credits they earn to pay down the surplus credits they spent earlier when CPU utilization falls below the
  baseline again.

Earning CPU credits to pay down surplus credits enables EC2 to average the CPU utilization of instances over a 24-hour
period.<br/>
If the average CPU usage over a 24-hour period **exceeds** the baseline, instances are
[billed for the additional usage](https://aws.amazon.com/ec2/pricing/on-demand/#T2.2FT3.2FT4g_Unlimited_Mode_Pricing).

## Spot instances

Refer:

- [Amazon EC2 Spot Instances]
- [Spot Instance interruptions]
- [EC2 instance rebalance recommendations]

Regular EC2 capacity offered at up to a 90% discount from On-Demand prices that can be reclaimed by AWS at any time.

Effective reclamation follows a 2-minute notification called the
[_Spot Instance Interruption Event_][spot instance interruptions].<br/>
Spot instances are a good fit for applications flexible, fault-tolerant, or stateless applications that are able to
gracefully handle this notification, and respond by check pointing or draining their work.

In addition to Interruption Notifications, AWS sends
[Rebalance Recommendation Events][ec2 instance rebalance recommendations] to spot instances that are at higher risk of
being interrupted.<br/>
Handling Rebalance Recommendations can potentially give an application more time to gracefully shutdown than the 2
minutes given by an Interruption Notification.

Test Spot Interruption Notifications and Rebalance Recommendations:

- _Locally_ (and not from EC2) using [EC2 Metadata Mock][aws/amazon-ec2-metadata-mock].
- _On EC2 instances_ using AWS' Fault Injection Simulator.

The [ec2-spot-interrupter CLI tool][aws/amazon-ec2-spot-interrupter] simplifies FIS' usage by getting a list of
instance IDs and using them to craft the required experiment templates and then execute those experiments.<br/>
See [Implementing interruption tolerance in Amazon EC2 Spot with AWS Fault Injection Simulator] for details.

## Disks

Refer [EBS].

Volumes being attached to an EC2 instance require a device name for the instance to refer to. The block device driver in
the OS then assigns the volume an internal device name when mounting it, which _can_ be different from the name given in
the volume's definition.
Refer [Device names for volumes on Amazon EC2 instances].

One or more Provisioned IOPS SSD (`io1` or `io2`) volumes can be attached to **up to 16 instances** as long as those
instances reside **in the same Availability Zone**.<br/>
Refer [Attach an EBS volume to multiple EC2 instances using Multi-Attach].

The maximum number of EBS volumes that instances can have attached depends on the instance's type and size.<br/>
Refer instance volume limits.

Each instance a volume is attached to has **full read and write permission** to the shared volume.<br/>
This allows to achieve higher application availability in applications that can manage concurrent write operations
effectively.

### Ephemeral storage

Refer [Instance store temporary block storage for EC2 instances] for temporary storage of information that changes
frequently (e.g. buffers, caches, scratch data, temporary content).

_Instance stores_ consist of one or more virtual volumes exposed as block devices.

The size of an instance store and the number of devices available, varies by instance type and size.<br/>
Not every instance type provides instance store volumes.

Virtual devices for instance store volumes are given device names in order from `ephemeral0` to `ephemeral23`.

There is no additional charge for using the instance store volumes provided with instances.<br/>
Instance store volumes are **included** as part of the usage cost of an instance.

## Monitoring

### Metrics

Instances publish _a default set_ of metrics to CloudWatch with no charge.<br/>
One can change this set by configuring the CloudWatch agent.

[Config file reference][manually create or edit the cloudwatch agent configuration file].<br/>
[Recommended alarms].

Refer:

- [Monitor your instances using CloudWatch].
- [How can I send memory and disk metrics from my EC2 instances to CloudWatch?].
- [Monitor AWS EC2 memory utilization and set CloudWatch Alarm].

> [!important]
> Make sure the instance the permissions it needs to publish extra metrics.<br/>
> Consider assigning it the AWS-managed `CloudWatchAgentServerPolicy` IAM policy or similar permissions.
>
> <details style='padding: 0 0 1rem 1rem'>
>
> ```json
> {
>     Version: "2012-10-17",
>     Statement: [{
>         Effect: "Allow",
>         Action: [
>             "ec2:DescribeTags",
>             "ec2:DescribeVolumes",
>             "cloudwatch:PutMetricData"
>         ],
>         Resource: "*"
>     }]
> }
> ```
>
> </details>

CloudWatch agent's logs are saved by default to `/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log`.

```sh
amazon-cloudwatch-agent-ctl -a 'status'
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a 'set-log-level' -l 'INFO'
amazon-cloudwatch-agent-ctl -a 'fetch-config' -m 'ec2' -s -c 'file:/opt/aws/amazon-cloudwatch-agent/bin/config.json'
tail -f '/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log'
```

## Auto scaling

Refer [Amazon EC2 Auto Scaling].

### Lifecycle hooks

Refer [Amazon EC2 Auto Scaling lifecycle hooks].

Also see [CompleteLifecycleAction].

## Image customization

Refer [Image Builder].

## Automatic recovery

Also see [Automatic instance recovery].

## Cost-saving measures

- Prefer using the most adequate instance type for the job.<br/>
  E.g., prefer `r*` instances instead of `m*` ones where a lot of RAM is needed, but almost no CPU power is.
- Prefer using ARM-based (`g`) instances, unless a different architecture is required.
- Prefer _shared_ instances over _dedicated_ ones unless necessary.
  Refer [Understanding AWS Tenancy Options].
- Prefer dedicated _instances_ over dedicated _hosts_ unless necessary.
  Refer [Understanding AWS Tenancy Options].
- Prefer using [burstable (`t`) instances][burstable instances], unless steady performance is required and specially
  for burstable workloads.
- When employing **underused** burstable instances, prefer re-launching them in `standard` mode to avoid paying for
  surplus credits.
- Prefer using [spot instances] instead of on-demand ones where possible.
- Consider **stopping** or (even better) deleting non-production hosts after working hours.
- Consider applying for EC2 Instance and/or Compute Savings Plans.
- Consider [archiving snapshots] should they not be accessed for 90d or more.<br/>
  Archiving has a 90d minimum storage fee, **and** archived resources have retrieval fees.

## Further readings

- [Amazon Web Services]
- [AWS EC2 Instance pricing comparison]
- [EC2Instances.info on vantage.sh]
- AWS' [CLI]
- [SSM]
- [Connect to your instances without requiring a public IPv4 address using EC2 Instance Connect Endpoint]
- [Unlimited mode for burstable performance instances]
- [Standard mode for burstable performance instances]
- [Configuring EC2 Disk alert using Amazon CloudWatch]
- [Using AL2023 based Amazon ECS AMIs to host containerized workloads]
- [Announcing Amazon EC2 per second billing]
- [How can I send memory and disk metrics from my EC2 instances to CloudWatch?]
- [Device names for volumes on Amazon EC2 instances]
- [Amazon EBS volume limits for Amazon EC2 instances]
- [Recommended alarms]
- [Image Builder]
- [Eventual consistency in the Amazon EC2 API]

### Sources

- [Using instance profiles]
- [DescribeImages] API
- [`describe-images`][describe-images] CLI subcommand
- [Best practices for handling EC2 Spot Instance interruptions]
- [IAM roles for Amazon EC2]
- [Retrieve instance metadata]
- [Burstable performance instances]
- [Change the instance type]
- [How to Clone instance EC2]
- [Create an AMI from an Amazon EC2 Instance]
- [Amazon EC2 Auto Scaling]
- [Amazon EC2 Auto Scaling lifecycle hooks]
- [CompleteLifecycleAction]
- [Instance store temporary block storage for EC2 instances]
- [Attach an EBS volume to multiple EC2 instances using Multi-Attach]
- [Monitor AWS EC2 memory utilization and set CloudWatch Alarm]
- [Automating Instance Reboots with Amazon CloudWatch EC2 Actions]
- [Understanding AWS Tenancy Options]
- [Find AMIs with the SSM Agent preinstalled]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Burstable instances]: #burstable-instances
[Spot instances]: #spot-instances

<!-- Knowledge base -->
[amazon web services]: README.md
[archiving snapshots]: ebs.md#archiving
[cli]: cli.md
[ebs]: ebs.md
[image builder]: image%20builder.md
[ssm]: ssm.md

<!-- Upstream -->
[amazon ebs volume limits for amazon ec2 instances]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/volume_limits.html
[amazon ec2 auto scaling lifecycle hooks]: https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html
[amazon ec2 auto scaling]: https://docs.aws.amazon.com/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html
[Amazon EC2 Spot Instances]: https://aws.amazon.com/ec2/spot/
[announcing amazon ec2 per second billing]: https://aws.amazon.com/about-aws/whats-new/2017/10/announcing-amazon-ec2-per-second-billing/
[attach an ebs volume to multiple ec2 instances using multi-attach]: https://docs.aws.amazon.com/ebs/latest/userguide/ebs-volumes-multi.html
[Automatic instance recovery]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-recover.html
[aws/amazon-ec2-metadata-mock]: https://github.com/aws/amazon-ec2-metadata-mock
[aws/amazon-ec2-spot-interrupter]: https://github.com/aws/amazon-ec2-spot-interrupter
[best practices for handling ec2 spot instance interruptions]: https://aws.amazon.com/blogs/compute/best-practices-for-handling-ec2-spot-instance-interruptions/
[burstable performance instances]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances.html
[change the instance type]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-resize.html
[completelifecycleaction]: https://docs.aws.amazon.com/autoscaling/ec2/APIReference/API_CompleteLifecycleAction.html
[connect to your instances without requiring a public ipv4 address using ec2 instance connect endpoint]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-with-ec2-instance-connect-endpoint.html
[create an ami from an amazon ec2 instance]: https://docs.aws.amazon.com/toolkit-for-visual-studio/latest/user-guide//tkv-create-ami-from-instance.html
[describe-images]: https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
[describeimages]: https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeImages.html
[device names for volumes on amazon ec2 instances]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html
[EC2 instance rebalance recommendations]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/rebalance-recommendations.html
[Eventual consistency in the Amazon EC2 API]: https://docs.aws.amazon.com/ec2/latest/devguide/eventual-consistency.html
[Find AMIs with the SSM Agent preinstalled]: https://docs.aws.amazon.com/systems-manager/latest/userguide/ami-preinstalled-agent.html
[how can i send memory and disk metrics from my ec2 instances to cloudwatch?]: https://repost.aws/knowledge-center/cloudwatch-memory-metrics-ec2
[how to clone instance ec2]: https://repost.aws/questions/QUOrWudF3vRL2Vqtrv0M9lfQ/how-to-clone-instance-ec2
[iam roles for amazon ec2]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html
[Implementing interruption tolerance in Amazon EC2 Spot with AWS Fault Injection Simulator]: https://aws.amazon.com/blogs/compute/implementing-interruption-tolerance-in-amazon-ec2-spot-with-aws-fault-injection-simulator/
[instance store temporary block storage for ec2 instances]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/InstanceStorage.html
[key concepts and definitions for burstable performance instances]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-credits-baseline-concepts.html
[Manually create or edit the CloudWatch agent configuration file]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html
[Monitor your instances using CloudWatch]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-cloudwatch.html
[recommended alarms]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html#EC2
[retrieve instance metadata]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html
[Spot Instance interruptions]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-interruptions.html
[standard mode for burstable performance instances]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances-standard-mode.html
[termination notifications]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-instance-termination-notices.html
[unlimited mode for burstable performance instances]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances-unlimited-mode.html
[using al2023 based amazon ecs amis to host containerized workloads]: https://docs.aws.amazon.com/linux/al2023/ug/ecs.html
[using instance profiles]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html

<!-- Others -->
[Automating Instance Reboots with Amazon CloudWatch EC2 Actions]: https://devops.supportsages.com/automating-instance-reboots-with-amazon-cloudwatch-ec2-actions-375f633a658d
[aws ec2 instance pricing comparison]: https://ec2instances.github.io/
[configuring ec2 disk alert using amazon cloudwatch]: https://medium.com/@chandinims001/configuring-ec2-disk-alert-using-amazon-cloudwatch-793807e40d72
[ec2instances.info on vantage.sh]: https://instances.vantage.sh/
[monitor aws ec2 memory utilization and set cloudwatch alarm]: https://medium.com/@VaibhaviDeshmukh07/monitor-aws-ec2-memory-utilization-and-set-cloudwatch-alarm-a53d0e0b1eeb
[Understanding AWS Tenancy Options]: https://medium.com/@simrankumari1344/understanding-aws-tenancy-options-shared-tenancy-dedicated-hosts-and-dedicated-instances-2221bc288a9b
