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

- **Avoid** executing SSM through commands like `xargs` or `parallel` like in the following:

  ```sh
  aws ec2 describe-instances --output text --query 'Reservations[].Instances[0].InstanceId' --filters … \
  | xargs -ot aws ssm start-session --target
  ```

  The middle commands start the session correctly, but will intercept traps like `CTRL-C` and stop their own execution
  terminating the SSM session.

  Prefer using the `describe-instance` command's output as input for the `start-session` command instead:

  ```sh
  aws ssm start-session --target "$( \
    aws ec2 describe-instances --output text --query 'Reservations[].Instances[0].InstanceId' --filters … \
  )"
  ```

## Integrate with Ansible

Create a dynamic inventory which name ends with `aws_ec2.yml` (e.g. `test.aws_ec2.yml` or simply `aws_ec2.yml`).<br/>
It needs to be named like that to be found by the
['community.aws.aws_ssm' connection plugin][community.aws.aws_ssm connection].

Refer the [amazon.aws.aws_ec2 inventory] for more information about the file specifications.

> [!important]
> Even if this is a YAML file, it must **not** start with '---'.<br/>
> Ansible will **fail** parsing it in this case.

```yml
plugin: amazon.aws.aws_ec2
region: eu-north-1
include_filters:
  - # exclude instances that are not running, which are inoperable
    instance-state-name: running
exclude_filters:
  - tag-key:
      - aws:eks:cluster-name  # skip EKS nodes, since they are managed in their own way
  - # skip GitLab Runners, since they are volatile and managed in their own way
    tag:Application:
      - GitLab
    tag:Component:
      - Runner
use_ssm_inventory:
  # requires 'ssm:GetInventory' permissions on 'arn:aws:ssm:<region>:<account-id>:*'
  # this makes the sync fail miserably if configured on AWX inventories
  true
hostnames:
  - instance-id
    # acts as keyword to use the instances' 'InstanceId' attribute
    # use 'private-ip-address' to use the instances' 'PrivateIpAddress' attribute instead
    # or any option in <https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html#options> really
keyed_groups:
  # add hosts to '<prefix>_<value>' groups for each aws_ec2 host's matching attribute
  # e.g.: 'arch_x86_64', 'os_Name_Amazon_Linux', 'tag_Name_GitLab_Server'
  - key: architecture
    prefix: arch
  - key: ssm_inventory.platform_name
    prefix: os_Name
  - key: ssm_inventory.platform_type
    prefix: os_Type
  - key: ssm_inventory.platform_version
    prefix: os_Version
  # - key: tags  # would create a group per each tag value; prefer limiting groups to the useful ones
  #   prefix: tag
  - key: tags.Team
    prefix: tag_Team
  - key: tags.Environment
    prefix: tag_Environment
  - key: tags.Application
    prefix: tag_Application
  - key: tags.Component
    prefix: tag_Component
  - key: tags.Name
    prefix: tag_Name
compose:
  # add extra host variables
  # use non-jinja values (e.g. strings) by wrapping them in two sets of quotes
  # if using awx, prefer keeping double quotes external (e.g. "'something'") as it just looks better in the ui
  ansible_connection: "'aws_ssm'"
  ansible_aws_ssm_region: "'eu-north-1'"
  ansible_aws_ssm_timeout: "'300'"
```

Pitfalls:

- One **shall not use the `remote_user` connection option**, as it is not supported by the plugin.<br/>
  From the [plugin notes][aws_ssm connection plugin notes]:

  > The `community.aws.aws_ssm` connection plugin does not support using the `remote_user` and `ansible_user`
  > variables to configure the remote user. The `become_user` parameter should be used to configure which user to run
  > commands as. Remote commands will often default to running as the `ssm-agent` user, however this will also depend
  > on how SSM has been configured.

- SSM sessions' duration is limited by SSM's _idle session timeout_ setting.<br/>
  That might impact tasks that need to run for more than said duration.

  <details style="padding: 0 0 1rem 1rem">

  Some modules (e.g.: `community.postgresql.postgresql_db`) got their session terminated and SSM retried the task,
  killing and restarting the running process.<br/>
  Since the process lasted more than the sessions' duration, it kept having its sessions terminated. The task failed
  when the SSM reached the set retries for the connection.

  </details>

  Consider extending the SSM idle session timeout setting, or using `async` tasks to circumvent this issue.<br/>
  Mind that `async` tasks come with their own SSM caveats.

- Since [SSM starts shell sessions under `/usr/bin`][gotchas], one must explicitly set Ansible's temporary directory to
  a folder the remote user can write to ([source][ansible temp dir change]).

  <details style="padding: 0 0 1rem 1rem">

  ```sh
  ANSIBLE_REMOTE_TMP="/tmp/.ansible/tmp" ansible…
  ```

  ```ini
  # file: ansible.cfg
  remote_tmp=/tmp/.ansible/tmp
  ```

  ```diff
   - hosts: all
  +  vars:
  +    ansible_remote_tmp: /tmp/.ansible/tmp
     tasks: …
  ```

  </details>

  This, or use the shell profiles in [SSM's preferences][session manager preferences] to change the directory when
  logged in.

- In similar fashion to the point above, SSM might mess up the directory used by `async` tasks.<br/>
  To avoid this, set it to a folder the remote user can write to.

  <details style="padding: 0 0 1rem 1rem">

  ```sh
  ANSIBLE_ASYNC_DIR="/tmp/.ansible-${USER}/async" ansible…
  ```

  ```ini
  # file: ansible.cfg
  async_dir=/tmp/.ansible-${USER}/async
  ```

  ```diff
   - hosts: all
  +  vars:
  +    ansible_async_dir: /tmp/.ansible/async
     tasks: …
  ```

  </details>

- When using `async` tasks, SSM will fire the task and disconnect<br/>
  This made the task **fail** at some point. Even so, the process will still run on the target host.

  <details style="padding: 0 0 1rem 1rem">

  ```json
  {
    "failed": 0,
    "started": 1,
    "finished": 0,
    "ansible_job_id": "j604343782826.4885",
    "results_file": "/tmp/.ansible/async/j604343782826.4885",
    "_ansible_suppress_tmpdir_delete": true
  }
  ```

  </details>

  Fire these tasks with `poll` set to `0` and forcing a specific failure test.<br/>
  Then, use a different task to check up on them.

  > [!important]
  > When checking up tasks with `ansible.builtin.async_status`, SSM will use a single connection.<br/>
  > Consider keeping alive said connection until the end of the task.
  >
  > FIXME: check. This seems to not happen anymore.

  <details style="padding: 0 0 1rem 1rem">
    <summary>Example</summary>

  ```yaml
  - name: Dump a PostgreSQL DB from an RDS instance
    hosts: all
    vars:
      ansible_connection: amazon.aws.aws_ssm
      ansible_remote_tmp: /tmp/.ansible/tmp             #-- see pitfalls (ssm starts sessions in '/usr/bin')
      ansible_async_dir: /tmp/.ansible/async            #-- see pitfalls (ssm starts sessions in '/usr/bin')
      pg_dump_max_wait_in_seconds: "{{ 60 * 60 * 2 }}"  #-- wait up to 2 hours (60s * 60m * 2h)
      pg_dump_check_delay_in_seconds: 60                #-- avoid overloading the ssm agent with sessions
      pg_dump_check_retries:                            #-- max_wait/delay
        "{{ pg_dump_max_wait_in_seconds/pg_dump_check_delay_in_seconds) }}"
    tasks:
      - name: Dump the DB from the RDS instance
        community.postgresql.postgresql_db: { … }
        async: "{{ pg_dump_max_wait_in_seconds | int }}"
        poll: 0                                         #-- fire and forget; ssm would not allow self-checking anyways
        register: pg_dump_task_execution                #-- expected: { "failed": 0, "started": 1, "finished": 0 }
        changed_when:
          - pg_dump_task_execution.started == 1
          - pg_dump_task_execution.failed  == 0
        failed_when: pg_dump_task_execution.failed  == 1  #-- specify the failure yourself
      - name: Check on the PG dump task
        vars:
          ansible_aws_ssm_timeout: "{{ pg_dump_max_wait_in_seconds }}"  #-- keep the connection active the whole time
          ansible_job_id: "{{ dump_stdout_as_obj.ansible_job_id }}"
        ansible.builtin.async_status:
          jid: "{{ pg_dump_task_execution.ansible_job_id }}"
        register: pg_dump_task_execution_result
        until: pg_dump_task_execution_result.finished
        retries: "{{ pg_dump_check_retries | int }}"          #-- mind the argument's type
        delay: "{{ pg_dump_check_delay_in_seconds | int }}"   #-- mind the argument's type
  ```

  </details>

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
- [Find AMIs with the SSM Agent preinstalled]

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
[snippets]: ../../../snippets/aws/

<!-- Upstream -->
[amazon.aws.aws_ec2 inventory]: https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html
[aws_ssm connection plugin notes]: https://docs.ansible.com/ansible/latest/collections/community/aws/aws_ssm_connection.html#notes
[community.aws.aws_ssm connection]: https://docs.ansible.com/ansible/latest/collections/community/aws/aws_ssm_connection.html
[session manager preferences]: https://console.aws.amazon.com/systems-manager/session-manager/preferences
[start a session]: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html
[troubleshooting managed node availability using ssm-cli]: https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-cli.html
[troubleshooting managed node availability]: https://docs.aws.amazon.com/systems-manager/latest/userguide/troubleshooting-managed-instances.html
[Find AMIs with the SSM Agent preinstalled]: https://docs.aws.amazon.com/systems-manager/latest/userguide/ami-preinstalled-agent.html

<!-- Others -->
[ansible temp dir change]: https://devops.stackexchange.com/questions/10703/ansible-temp-dir-change
[how can i change the session manager shell to bash on ec2 linux instances?]: https://repost.aws/knowledge-center/ssm-session-manager-change-shell
[using ansible in aws]: https://rhuaridh.co.uk/blog/ansible-in-aws.html
