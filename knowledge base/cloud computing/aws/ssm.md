# AWS Systems Manager

1. [TL;DR](#tldr)
1. [Requirements](#requirements)
1. [Gotchas](#gotchas)
1. [Integrate with Ansible](#integrate-with-ansible)
1. [Troubleshooting](#troubleshooting)
   1. [Check node availability using `ssm-cli`](#check-node-availability-using-ssm-cli)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Usage</summary>

```sh
# Get connection statuses.
aws ssm get-connection-status --target 'instance-id'

# Start sessions.
aws ssm start-session --target 'instance-id'

# Run commands.
aws ssm start-session \
  --target 'instance-id' \
  --document-name 'CustomCommandSessionDocument' \
  --parameters '{"logpath":["/var/log/amazon/ssm/amazon-ssm-agent.log"]}'
aws ssm send-command \
  --instance-ids 'i-0123456789abcdef0' \
  --document-name 'AWS-RunShellScript' \
  --parameters "commands="echo 'hallo'"

# Wait for commands execution.
aws ssm wait command-executed --instance-id 'i-0123456789abcdef0' --command-id 'abcdef01-2345-abcd-6789-abcdef012345'

# Get commands results.
aws ssm get-command-invocation --instance-id 'i-0123456789abcdef0' --command-id 'abcdef01-2345-abcd-6789-abcdef012345'
aws ssm get-command-invocation \
  --instance-id 'i-0123456789abcdef0' --command-id 'abcdef01-2345-abcd-6789-abcdef012345' \
  --query '{"status": Status, "rc": ResponseCode, "stdout": StandardOutputContent, "stderr": StandardErrorContent}'
```

</details>
<details>
  <summary>Real world use cases</summary>

Also check out the [snippets].

```sh
# Connect to instances if they are available.
instance_id='i-08fc83ad07487d72f' \
&& eval $(aws ssm get-connection-status --target "$instance_id" --query "Status=='connected'" --output 'text') \
&& aws ssm start-session --target "$instance_id" \
|| (echo "instance ${instance_id} not available" >&2 && false)

# Run commands and get their output.
instance_id='i-0915612f182914822' \
&& command_id=$(aws ssm send-command --instance-ids "$instance_id" \
  --document-name 'AWS-RunShellScript' --parameters 'commands="echo hallo"' \
  --query 'Command.CommandId' --output 'text') \
&& aws ssm wait command-executed --command-id "$command_id" --instance-id "$instance_id" \
&& aws ssm get-command-invocation --command-id "$command_id" --instance-id "$instance_id" \
  --query '{"status": Status, "rc": ResponseCode, "stdout": StandardOutputContent, "stderr": StandardErrorContent}'
```

</details>

## Requirements

For instances to be managed by Systems Manager and be available in lists of managed nodes, it must:

- Run a supported operating system.
- Have the SSM Agent installed **and running**.

  ```sh
  sudo dnf -y install 'amazon-ssm-agent'
  sudo systemctl enable --now 'amazon-ssm-agent.service'
  ```

- Have an AWS IAM instance profile attached with the correct permissions.<br/>
  The instance profile enables the instance to communicate with the Systems Manager service.
  **Alternatively**, the instance must be registered to Systems Manager using hybrid activation.

  The minimum permissions required are given by the Amazon-provided `AmazonSSMManagedInstanceCore` policy
  (`arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore`).

- Be able to to connect to a Systems Manager endpoint through the SSM Agent in order to register with the service.<br/>
  From there, the instance must be available to the service. This is confirmed by the service by sending a signal every
  five minutes to check the instance's health.

  After the status of a managed node has been `Connection Lost` for at least 30 days, the node could be removed from the
  Fleet Manager console.<br/>
  To restore it to the list, resolve the issues that caused the lost connection.

Check whether SSM Agent successfully registered with the Systems Manager service by executing the `aws ssm
describe-instance-associations-status` command.<br/>
It won't return results until a successful registration has taken place.

```sh
aws ssm describe-instance-associations-status --instance-id 'instance-id'
```

<details>
  <summary>Failed invocation</summary>

```json
{
  "InstanceAssociationStatusInfos": []
}
```

</details>
<details>
  <summary>Successful invocation</summary>

```json
{
  "InstanceAssociationStatusInfos": [
    {
      "AssociationId": "51f0ed7e-c236-4c34-829d-e8f2a7a3bb4a",
      "Name": "AWS-GatherSoftwareInventory",
      "DocumentVersion": "1",
      "AssociationVersion": "2",
      "InstanceId": "i-0123456789abcdef0",
      "ExecutionDate": "2024-04-22T14:41:37.313000+02:00",
      "Status": "Success",
      "ExecutionSummary": "1 out of 1 plugin processed, 1 success, 0 failed, 0 timedout, 0 skipped. ",
      "AssociationName": "InspectorInventoryCollection-do-not-delete"
    },
    …
  ]
}
```

</details>

## Gotchas

- SSM starts shell sessions under `/usr/bin`
  ([source][how can i change the session manager shell to bash on ec2 linux instances?]):

  > **Other shell profile configuration options**<br/>
  > By default, Session Manager starts in the "/usr/bin" directory.

## Integrate with Ansible

Create a dynamic inventory which name ends with `aws_ec2.yml` (e.g. `test.aws_ec2.yml` or simply `aws_ec2.yml`).<br/>
Refer the [amazon.aws.aws_ec2 inventory] for more information about the file specifications.<br/>
It needs to be named like that to be found by the
['community.aws.aws_ssm' connection plugin][community.aws.aws_ssm connection].

```yml
# File: 'aws_ec2.yml'.
plugin: aws_ec2
regions:
  - eu-east-2
exclude_filters:
  - tag-key:
      - aws:eks:cluster-name  # EKS nodes do not use SSM-capable images
include_filters:
  - instance-state-name: running
keyed_groups:
  - key: tags.Name
    # add hosts to 'tag_Name_<tag_value>' groups for each aws_ec2 host's 'Tags.Name' attribute
    prefix: tag_Name_
    separator: ""
  - key: tags.application
    # add hosts to 'tag_application_<tag_value>' groups for each aws_ec2 host's 'Tags.application' attribute
    prefix: tag_application_
    separator: ""
hostnames:
  - instance-id
    # acts as keyword to use the instances' 'InstanceId' attribute
    # use 'private-ip-address' to use the instances' 'PrivateIpAddress' attribute instead
    # or any option in <https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html#options> really
```

Pitfalls:

- One **shall not use the `remote_user` connection option**, as it is not supported by the plugin.<br/>
  From the [plugin notes][aws_ssm connection plugin notes]:

  > The `community.aws.aws_ssm` connection plugin does not support using the `remote_user` and `ansible_user` variables
  > to configure the remote user.  The `become_user` parameter should be used to configure which user to run commands
  > as. Remote commands will often default to running as the `ssm-agent` user, however this will also depend on how SSM
  > has been configured.

- Since [SSM starts shell sessions under `/usr/bin`][gotchas], one must explicitly set Ansible's temporary directory to
  a folder the remote user can write to ([source][ansible temp dir change]):

  ```sh
  ANSIBLE_REMOTE_TMP='/tmp' ansible…
  ```

  ```ini
  # file: ansible.cfg
  remote_tmp=/tmp
  ```

  ```diff
   - hosts: all
  +  vars:
  +    ansible_remote_tmp: /tmp
     tasks: …
  ```

  This, or use the shell profiles in [SSM's preferences][session manager preferences] to change the directory when
  logged in.

## Troubleshooting

Refer [Troubleshooting managed node availability].

1. Check the [Requirements] are satisfied.
1. [Check node availability using `ssm-cli`][check node availability using ssm-cli].

### Check node availability using `ssm-cli`

Refer
[Troubleshooting managed node availability using `ssm-cli`][troubleshooting managed node availability using ssm-cli].

From the managed instance:

```sh
$ sudo dnf -y install 'amazon-ssm-agent'
$ sudo systemctl enable --now 'amazon-ssm-agent.service'
$ sudo ssm-cli get-diagnostics --output 'table'
┌──────────────────────────────────────┬─────────┬─────────────────────────────────────────────────────────────────────┐
│ Check                                │ Status  │ Note                                                                │
├──────────────────────────────────────┼─────────┼─────────────────────────────────────────────────────────────────────┤
│ EC2 IMDS                             │ Success │ IMDS is accessible and has instance id i-0123456789abcdef0 in       │
│                                      │         │ region eu-west-1                                                    │
├──────────────────────────────────────┼─────────┼─────────────────────────────────────────────────────────────────────┤
│ Hybrid instance registration         │ Skipped │ Instance does not have hybrid registration                          │
├──────────────────────────────────────┼─────────┼─────────────────────────────────────────────────────────────────────┤
│ Connectivity to ssm endpoint         │ Success │ ssm.eu-west-1.amazonaws.com is reachable                            │
├──────────────────────────────────────┼─────────┼─────────────────────────────────────────────────────────────────────┤
│ Connectivity to ec2messages endpoint │ Success │ ec2messages.eu-west-1.amazonaws.com is reachable                    │
├──────────────────────────────────────┼─────────┼─────────────────────────────────────────────────────────────────────┤
│ Connectivity to ssmmessages endpoint │ Success │ ssmmessages.eu-west-1.amazonaws.com is reachable                    │
├──────────────────────────────────────┼─────────┼─────────────────────────────────────────────────────────────────────┤
│ Connectivity to s3 endpoint          │ Success │ s3.eu-west-1.amazonaws.com is reachable                             │
├──────────────────────────────────────┼─────────┼─────────────────────────────────────────────────────────────────────┤
│ Connectivity to kms endpoint         │ Success │ kms.eu-west-1.amazonaws.com is reachable                            │
├──────────────────────────────────────┼─────────┼─────────────────────────────────────────────────────────────────────┤
│ Connectivity to logs endpoint        │ Success │ logs.eu-west-1.amazonaws.com is reachable                           │
├──────────────────────────────────────┼─────────┼─────────────────────────────────────────────────────────────────────┤
│ Connectivity to monitoring endpoint  │ Success │ monitoring.eu-west-1.amazonaws.com is reachable                     │
├──────────────────────────────────────┼─────────┼─────────────────────────────────────────────────────────────────────┤
│ AWS Credentials                      │ Success │ Credentials are for                                                 │
│                                      │         │ arn:aws:sts::012345678901:assumed-role/managed/i-0123456789abcdef0  │
│                                      │         │ and will expire at 2024-04-22 18:19:48 +0000 UTC                    │
├──────────────────────────────────────┼─────────┼─────────────────────────────────────────────────────────────────────┤
│ Agent service                        │ Success │ Agent service is running and is running as expected user            │
├──────────────────────────────────────┼─────────┼─────────────────────────────────────────────────────────────────────┤
│ Proxy configuration                  │ Skipped │ No proxy configuration detected                                     │
├──────────────────────────────────────┼─────────┼─────────────────────────────────────────────────────────────────────┤
│ SSM Agent version                    │ Success │ SSM Agent version is 3.3.131.0 which is the latest version          │
└──────────────────────────────────────┴─────────┴─────────────────────────────────────────────────────────────────────┘
```

## Further readings

- [Amazon Web Services]
- AWS' [CLI]
- [Ansible]
- [EC2]

### Sources

- [Start a session]
- [Using Ansible in AWS]
- [How can i change the session manager shell to BASH on EC2 linux instances?]
- [Using Ansible in AWS]
- [Troubleshooting managed node availability]
- [Troubleshooting managed node availability using `ssm-cli`][troubleshooting managed node availability using ssm-cli]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[check node availability using ssm-cli]: #check-node-availability-using-ssm-cli
[gotchas]: #gotchas
[requirements]: #requirements

<!-- Knowledge base -->
[ansible]: ../../ansible.md
[amazon web services]: README.md
[cli]: cli.md
[ec2]: ec2.md
[snippets]: ../../../snippets/aws/commands.fish

<!-- Upstream -->
[amazon.aws.aws_ec2 inventory]: https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html
[aws_ssm connection plugin notes]: https://docs.ansible.com/ansible/latest/collections/community/aws/aws_ssm_connection.html#notes
[community.aws.aws_ssm connection]: https://docs.ansible.com/ansible/latest/collections/community/aws/aws_ssm_connection.html
[session manager preferences]: https://console.aws.amazon.com/systems-manager/session-manager/preferences
[start a session]: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html
[troubleshooting managed node availability using ssm-cli]: https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-cli.html
[troubleshooting managed node availability]: https://docs.aws.amazon.com/systems-manager/latest/userguide/troubleshooting-managed-instances.html

<!-- Others -->
[ansible temp dir change]: https://devops.stackexchange.com/questions/10703/ansible-temp-dir-change
[how can i change the session manager shell to bash on ec2 linux instances?]: https://repost.aws/knowledge-center/ssm-session-manager-change-shell
[using ansible in aws]: https://rhuaridh.co.uk/blog/ansible-in-aws.html
