# SSM

1. [TL;DR](#tldr)
1. [Gotchas](#gotchas)
1. [Integrate with Ansible](#integrate-with-ansible)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Usage</summary>

```sh
# Start sessions.
aws ssm start-session --target 'instance-id'

# Run commands.
aws ssm start-session \
  --target 'instance-id' \
  --document-name 'CustomCommandSessionDocument' \
  --parameters '{"logpath":["/var/log/amazon/ssm/amazon-ssm-agent.log"]}'
```

</details>

<details>
  <summary>Real world use cases</summary>
</details>

## Gotchas

- SSM starts shell sessions under `/usr/bin` ([source][how can i change the session manager shell to bash on ec2 linux instances?]):

  > **Other shell profile configuration options**<br/>
  > By default, Session Manager starts in the "/usr/bin" directory.

## Integrate with Ansible

Create a dynamic inventory named `aws_ec2.yml`.<br/>
It needs to be named like that to be found by the ['community.aws.aws_ssm' connection plugin][community.aws.aws_ssm connection].

```yml
# File: 'aws_ec2.yml'.
plugin: aws_ec2
regions:
  - eu-west-1
keyed_groups:
  - key: tags.application
    # add hosts to tag_application_<tag_value> groups for each aws_ec2 host's
    # tags.application attribute
    prefix: tag_application_
    separator: ""
  - key: tags.Name
    # add hosts to tag_Name_<tag_value> groups for each aws_ec2 host's tags.Name
    # attribute
    prefix: tag_Name_
    separator: ""
hostnames:
  - <instance-id>
```

Pitfalls:

- One **shall not use the `remote_user` connection option**, as it is not supported by the plugin.<br/>
  From the [plugin notes][aws_ssm connection plugin notes]:

  > The `community.aws.aws_ssm` connection plugin does not support using the `remote_user` and `ansible_user` variables to configure the remote user.  The ``become_user`` parameter should be used to configure which user to run commands as. Remote commands will often default to running as the `ssm-agent` user, however this will also depend on how SSM has been configured.

- Since [SSM starts shell sessions under `/usr/bin`][gotchas], one must explicitly set Ansible's temporary directory to a folder the remote user can write to ([source][ansible temp dir change]):

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

## Further readings

- [Ansible]
- [EC2]

### Sources

- [Start a session]
- [Using Ansible in AWS]
- [How can i change the session manager shell to BASH on EC2 linux instances?]
- [Using Ansible in AWS]

<!--
  References
  -->

<!-- In-article sections -->
[gotchas]: #gotchas

<!-- Knowledge base -->
[ansible]: ../../ansible.md
[ec2]: ec2.md

<!-- Upstream -->
[start a session]: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html
[session manager preferences]: https://eu-west-1.console.aws.amazon.com/systems-manager/session-manager/preferences?region=eu-west-1
[aws_ssm connection plugin notes]: https://docs.ansible.com/ansible/latest/collections/community/aws/aws_ssm_connection.html#notes

<!-- Others -->
[ansible temp dir change]: https://devops.stackexchange.com/questions/10703/ansible-temp-dir-change
[how can i change the session manager shell to bash on ec2 linux instances?]: https://repost.aws/knowledge-center/ssm-session-manager-change-shell
[using ansible in aws]: https://rhuaridh.co.uk/blog/ansible-in-aws.html
