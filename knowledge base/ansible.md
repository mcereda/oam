# Ansible

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
   1. [Performance tuning](#performance-tuning)
1. [Inventories](#inventories)
   1. [AWS](#aws)
   1. [Patterns](#patterns)
1. [Variables](#variables)
1. [Templating](#templating)
   1. [Tests](#tests)
   1. [Loops](#loops)
1. [Use raw strings](#use-raw-strings)
1. [Validation](#validation)
   1. [Assertions](#assertions)
1. [Asynchronous actions](#asynchronous-actions)
   1. [Run tasks in parallel](#run-tasks-in-parallel)
1. [Error handling](#error-handling)
   1. [Using blocks](#using-blocks)
1. [Output formatting](#output-formatting)
1. [Handlers](#handlers)
1. [Roles](#roles)
    1. [Get roles](#get-roles)
    1. [Assign roles](#assign-roles)
    1. [Role dependencies](#role-dependencies)
1. [Create custom filter plugins](#create-custom-filter-plugins)
1. [Execution environments](#execution-environments)
    1. [Build execution environments](#build-execution-environments)
1. [Ansible Navigator](#ansible-navigator)
    1. [Navigator configuration files](#navigator-configuration-files)
1. [Secrets management](#secrets-management)
    1. [Hiding sensitive values in verbose runs](#hiding-sensitive-values-in-verbose-runs)
    1. [Ansible Vault](#ansible-vault)
1. [Best practices](#best-practices)
1. [Troubleshooting](#troubleshooting)
    1. [ERROR: Ansible could not initialize the preferred locale: unsupported locale setting](#error-ansible-could-not-initialize-the-preferred-locale-unsupported-locale-setting)
    1. [Print all known variables](#print-all-known-variables)
    1. [Force notified handlers to run at a specific point](#force-notified-handlers-to-run-at-a-specific-point)
    1. [Time tasks execution](#time-tasks-execution)
    1. [Run specific tasks even in check mode](#run-specific-tasks-even-in-check-mode)
    1. [Dry-run only specific tasks](#dry-run-only-specific-tasks)
    1. [Set up recursive permissions on a directory so that directories are set to 755 and files to 644](#set-up-recursive-permissions-on-a-directory-so-that-directories-are-set-to-755-and-files-to-644)
    1. [Only run a task when another has a specific result](#only-run-a-task-when-another-has-a-specific-result)
    1. [Define when a task changed or failed](#define-when-a-task-changed-or-failed)
    1. [Set environment variables for a play, role or task](#set-environment-variables-for-a-play-role-or-task)
    1. [Set variables to the value of environment variables](#set-variables-to-the-value-of-environment-variables)
    1. [Check if a list contains an item and fail otherwise](#check-if-a-list-contains-an-item-and-fail-otherwise)
    1. [Define different values for `true`/`false`/`null`](#define-different-values-for-truefalsenull)
    1. [Force a task or play to use a specific Python interpreter](#force-a-task-or-play-to-use-a-specific-python-interpreter)
    1. [Provide a template file content inline](#provide-a-template-file-content-inline)
    1. [Python breaks in OS X](#python-breaks-in-os-x)
    1. [Load files' content into variables](#load-files-content-into-variables)
    1. [Only run a task when explicitly requested](#only-run-a-task-when-explicitly-requested)
    1. [Using AWS' SSM with Ansible fails with error _Failed to create temporary directory_](#using-aws-ssm-with-ansible-fails-with-error-failed-to-create-temporary-directory)
    1. [Future feature annotations is not defined](#future-feature-annotations-is-not-defined)
    1. [Boolean variables given from the CLI are treated as strings](#boolean-variables-given-from-the-cli-are-treated-as-strings)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

> [!tip]
> Prefer installing Ansible in a project's Python virtual environment.

```sh
# Install.
pipx install 'ansible'
pip3 install --user --require-virtualenv 'ansible'
brew install 'ansible' 'sshpass'         # darwin
sudo pamac install 'ansible' 'sshpass'   # manjaro linux

# Generate example configuration files with entries disabled.
ansible-config init --disabled > 'ansible.cfg'
ansible-config init --disabled -t 'all' > ~/'.ansible.cfg'

# Show the current configuration.
ansible-config dump
```

</details>

<details>
  <summary>Usage</summary>

```sh
# List hosts.
ansible-inventory -i 'inventory' --list
ansible-playbook -i 'inventory' 'playbook.yml' --list-hosts
ansible -i 'inventory' all --list-hosts

# Check the syntax of a playbook.
# This will *not* execute the plays inside it.
ansible-playbook 'path/to/playbook.yml' --syntax-check

# Execute playbooks.
ansible-playbook 'path/to/playbook.yml' -i 'hosts.list'
ansible-playbook … -i 'host1,host2,hostN,' -l 'hosts,list'
ansible-playbook … -i 'host1,host2,other,' -l 'hosts-pattern' --step
ansible-playbook … -e 'someKey=someValue someOtherKey=someOtherValue' -e 'extraKey=extraValue'
ansible-playbook … -e '{ "boolean_value_requires_json_format": true, "some_list": [ true, "someString" ] }'

# Show what changes (with details) a play would apply to the local machine.
ansible-playbook 'path/to/playbook.yml' -i 'localhost,' -c 'local' -vvC

# Only execute tasks with specific tags.
ansible-playbook 'path/to/playbook.yml' --tags 'configuration,packages'
ansible-playbook -i 'localhost,' -c 'local' -Dvvv 'playbook.yml' -t 'container_registry' --ask-vault-pass

# Avoid executing tasks with specific tags.
ansible-playbook 'path/to/playbook.yml' --skip-tags 'system,user'

# Check what tasks will be executed.
ansible-playbook 'path/to/playbook.yml' --list-tasks
ansible-playbook … --list-tasks --tags 'configuration,packages'
ansible-playbook … --list-tasks --skip-tags 'system,user'

# Debug playbooks.
ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-playbook …

# Record how much time tasks take.
ANSIBLE_CALLBACKS_ENABLED='profile_tasks' ansible-playbook …

# Encrypt data using Vault.
ansible-vault encrypt_string --name 'command_output' 'somethingNobodyShouldKnow'
ansible-vault encrypt '.ssh/id_rsa' --vault-password-file 'password_file.txt'
ANSIBLE_VAULT_PASSWORD_FILE='password_file.txt' ansible-vault encrypt --output 'ssh.key' '.ssh/id_rsa'

# Print out decoded contents of files encrypted with Vault.
ansible-vault view 'ssh.key.pub'
ansible-vault view 'ssh.key.pub' --vault-password-file 'password_file.txt'

# Edit decoded contents of files encrypted with Vault.
ANSIBLE_VAULT_PASSWORD='abracadabra' ansible-vault edit 'ssh.key.pub'
ansible-vault edit 'ssh.key.pub' --vault-password-file 'password_file.txt'

# Decrypt files encrypted with Vault.
ansible-vault decrypt 'ssh.key'
ansible-vault decrypt --output '.ssh/id_rsa' --vault-password-file 'password_file.txt' 'ssh.key'

# List roles installed from Galaxy.
ansible-galaxy list

# Install roles from Galaxy.
ansible-galaxy install 'namespace.role'
ansible-galaxy install --roles-path 'path/to/ansible/roles' 'namespace.role'
ansible-galaxy install 'namespace.role,v1.0.0'
ansible-galaxy install 'git+https://github.com/namespace/role.git,commit-hash'
ansible-galaxy install -r 'requirements.yml'

# Create new roles.
ansible-galaxy init 'role_name'
ansible-galaxy role init --type 'container' --init-path 'path/to/role' 'name'

# Remove roles installed from Galaxy.
ansible-galaxy remove 'namespace.role'
```

</details>

<details style="padding-bottom: 1em">
  <summary>Real world use cases</summary>

```sh
# Show hosts' ansible facts.
ansible -i 'path/to/hosts/file' -m 'setup' all
ansible -i 'host1,hostN,' -m 'setup' 'host1' -u 'remote-user'
ansible -i 'localhost,' -c 'local' -km 'setup' 'localhost'

# Execute locally using Ansible from the virtual environment in the current directory.
venv/bin/python3ansible -i 'localhost ansible_python_interpreter=venv/bin/python3,' -c 'local' \
  -m 'ansible.builtin.copy' -a 'src=/tmp/src' -a 'dest=/tmp/dest' 'localhost'

# Check the Vault password file is correct.
diff 'path/to/plain/file' <(ansible-vault view --vault-password-file 'password_file.txt' 'path/to/vault/encrypted/file')

# Use AWS SSM for connections.
ansible-playbook 'playbook.yaml' -DCvvv \
  -e 'ansible_aws_ssm_plugin=/usr/local/sessionmanagerplugin/bin/session-manager-plugin ansible_connection=aws_ssm' \
  -e 'ansible_aws_ssm_bucket_name=ssm-bucket ansible_aws_ssm_region=eu-west-1' \
  -e 'ansible_remote_tmp=/tmp/.ansible/tmp' \
  -i 'i-0123456789abcdef0,'
```

</details>

Galaxy collections and roles worth a check:

| ID                                             | Type       | Description           |
| ---------------------------------------------- | ---------- | --------------------- |
| [sivel.toiletwater][galaxy  sivel.toiletwater] | collection | Extra filters, mostly |

UIs:

| UI             | Static inventories | Dynamic inventories |
| -------------- | ------------------ | ------------------- |
| [AWX]          | ✓                  | ✓                   |
| [Rundeck]      | ✓                  | ?                   |
| [Semaphore UI] | ✓                  | ✗                   |
| [Zuul]         | ?                  | ?                   |

## Configuration

Ansible can be configured using INI files named `ansible.cfg`, environment variables, command-line options, playbook
keywords, and variables.

The `ansible-config` utility allows to see all the configuration settings available, their defaults, how to set them and
where their current value comes from.

Ansible will process the following list and use the **first** file it founds, ignoring all the others even if they do
exist:

1. the `ANSIBLE_CONFIG` environment variable;
1. the `ansible.cfg` file in the current directory;
1. the `~/.ansible.cfg` file in the user's home directory;
1. the `/etc/ansible/ansible.cfg` file.

Generate a fully commented-out example of the `ansible.cfg` file:

```sh
ansible-config init --disabled > 'ansible.cfg'

# Includes existing plugins.
ansible-config init --disabled -t all > 'ansible.cfg'
```

One _can_ specify string values containing environment variables in the configuration file, e.g.:

```ini
[defaults]
remote_tmp = /tmp/ansible-${USER}/tmp
```

> [!warning]
> As of 2025-08-06, environment variables set in a configuration file are **not** expanded.<br/>
> Refer [async_dir not properly expanding variables].

Those values are passed to Ansible during execution **as-is**.<br/>
Since they are sometimes given as part of CLI commands, they might™ work as expected. Most of the times, in my
experience, they **did not**.

There are _some_ shell-expanded characters that do seem to mostly work, though, like `~`:

```ini
[defaults]
async_dir = ~/.ansible/async
```

> [!tip]
> Prefer just using static values in the configuration file.

### Performance tuning

Refer the following:

- [8 ways to speed up your Ansible playbooks]
- [6 ways to speed up Ansible playbook execution]
- [How to speed up Ansible playbooks drastically?]
- [Easy things you can do to speed up ansible]

Suggestions:

- Optimize fact gathering:

  - Disable fact gathering when not used.
  - Consider using smart fact gathering:

    ```ini
    [defaults]
    gathering = smart
    fact_caching = jsonfile
    fact_caching_connection = /tmp/ansible/facts.json  ; /tmp/ansible to use the directory and have a file per host
    fact_caching_timeout = 86400
    ```

  - Only gather subsets of facts:

    ```yaml
    - name: Play with selected facts
      gather_facts: true
      gather_subset:
        - '!all'
        - '!min'
        - system
    ```

    Refer the [setup module] for more information, and the [setup module source code] for available keys.

- Consider increasing the number of forks when dealing with lots of managed hosts:

  ```ini
  [defaults]
  forks = 25
  ```

- Set **independent** tasks as async.
- Optimize SSH connections:

  - Prefer key-based authentication if used:

    ```ini
    [ssh_connection]
    ssh_args = -o PreferredAuthentications=publickey
    ```

  - Use pipelining:

    ```ini
    [ssh_connection]
    pipelining = True
    ```

  - Consider using multiplexing:

    ```ini
    [ssh_connection]
    ssh_args = -o ControlMaster=auto -o ControlPersist=3600s
    ```

- Consider installing and using the [Mitogen plugin][mitogen for ansible] on the controller:

  ```sh
  curl -fsLO 'https://github.com/mitogen-hq/mitogen/releases/download/v0.3.7/mitogen-0.3.7.tar.gz'
  tar -xaf 'mitogen-0.3.7.tar.gz'
  ```

  ```ini
  [defaults]
  strategy_plugins = mitogen-0.3.7/ansible_mitogen/plugins/strategy
  strategy = mitogen_linear
  ```

  > Be advised that mitogen is not really supported by Ansible and has some issues with privilege escalation
  > ([1](https://github.com/mitogen-hq/mitogen/issues/466)).

- Improve the code:

  - Bundle up package installations together.
  - Beware of _expensive_ calls.

## Inventories

```ini
saturn ansible_python_interpreter=/usr/bin/python3.12 ansible_connection=local
jupiter.lan ansible_python_interpreter=/usr/bin/python3 ansible_port=4444

[accessed_remotely]
saturn
jupiter.lan
uranus.example.com ansible_port=5987

[swap_resistent]
jupiter.lan
saturn

[workstations]
saturn
; mars.lan ansible_port=4444
```

### AWS

Refer [Integrate with AWS SSM].

### Patterns

Refer [Patterns: targeting hosts and groups].

They allow to specify hosts and/or groups from the inventory. Ansible will execute on all hosts included in the pattern.

They can refer to a single host, an IP address, an inventory group, a set of groups, or all hosts.<br/>
One can exclude or require subsets of hosts, use wildcards or regular expressions, and more.

Use either a `,` or a `:` to separate lists of hosts.<br/>
The `,` is preferred when dealing with ranges and IPv6 addresses.

| What                   | Patterns                               | Targets                                                                         |
| ---------------------- | -------------------------------------- | ------------------------------------------------------------------------------- |
| Everything             | `all`,  `*`                            | All hosts                                                                       |
| Single host            | `fqdn`, `192.168.1.1`, `localhost`     | The single host directly identified by the pattern                              |
| Multiple hosts         | `host1:host2`, `host1,host2`           | All hosts directly identified by the pattern                                    |
| Single group           | `webservers`, `tag_Application_Gitlab` | All hosts in the group identified by the pattern                                |
| Multiple groups        | `webservers:dbservers`                 | All hosts in all groups identified by the pattern                               |
| Exclude groups         | `webservers:!atlanta`                  | All hosts in the specified groups **not** identified by the **negated** pattern |
| Intersection of groups | `webservers:&staging`                  | All hosts present in **all** the groups identified by the pattern               |

One can use **wildcard** patterns with FQDNs or IP addresses, as long as the hosts are named in your inventory by FQDN
or IP address.

## Variables

Refer [Using variables].

In general, Ansible gives precedence to those variables that were defined more recently, actively, and/or with more
_explicit_ (and **not** necessarily _strict_) scope.

Undefined variables are assigned the values defined in a role's `default` directory, if any.<br/>
Host and/or inventory variables override roles' defaults.<br/>
Definitions in a role's `vars` directory override previous definitions of the same variables in the role's namespace
(including defaults).<br/>
Explicit includes (e.g., an `include_vars` task) override existing values.

Different variables sets in inventories are merged so that more specific settings override more generic ones.<br/>
E.g., `ansible_user` specified as `host_var` overrides `ansible_ssh_user` specified as `group_var`.

The current hierarchy is as follows (from lowest to highest priority, with the last setting overriding previous ones):

1. Ansible direct command line values like `-u my_user` (these are **not** considered variables).
1. Files in roles' `defaults` directory.<br/>
   Tasks inside a role see their own role's defaults; tasks defined outside of a role see the defaults of the last role.
1. Group variables defined in inventory files or provided by dynamic inventories.
1. Shared group variables in inventories (`group_vars/all`).
1. Shared group variables in playbooks (`group_vars/all`).
1. Child-specific group variables in inventories (`group_vars/*`).
1. Child-specific group variables in playbooks (`group_vars/*`).
1. Host variables defined in inventory files or provided by dynamic inventories.
1. Host variables in inventories (`host_vars/*`).
1. Host variables in playbooks (`host_vars/*`).
1. Host facts and **cached** `set_facts`.
1. Play-specific variables defined in the `vars` key.
1. Play-specific variables defined in the `vars_prompt` key.
1. Play-specific variables defined in the `vars_files` key.
1. Files in roles' `vars` directory.
1. Block-specific variables.
1. Task-specific variables.
1. Values from included variables (`include_vars`).
1. Values from `set_facts` and `register`ed as output of tasks.
1. Parameters from a play's `role` key and `include_role` tasks.
1. Parameters from `import_tasks` and `include_tasks` statements.
1. Extra variables specified in the command line like `-e "user=my_user"`.

> [!warning]
> Values set in the `vars` key of `import_tasks` or `include_tasks` statements did **not** always override the ones
> configured in the `vars` key of imported tasks.<br/>
> While this _may_ very well be a skill issue of mine, one can get around this by setting defaults for modules in the
> modules' attributes themselves, e.g.:
>
> ```diff
>  - name: Create an RDS DB instance
> -  vars:
> -    allow_major_version_upgrade: false
> -    auto_minor_version_upgrade: true
> -    availability_zone: eu-north-1a
>    amazon.aws.rds_instance:
> -    allow_major_version_upgrade: "{{ allow_major_version_upgrade }}"
> -    auto_minor_version_upgrade: "{{ auto_minor_version_upgrade }}"
> -    availability_zone: "{{ availability_zone }}"
> +    allow_major_version_upgrade: "{{ allow_major_version_upgrade | default(false) | bool }}"
> +    auto_minor_version_upgrade: "{{ auto_minor_version_upgrade | default(true) | bool }}"
> +    availability_zone: "{{ availability_zone | default('eu-west-1b') }}"
> ```

Consider setting _private_ defaults when some variables depend on multiple other variables (e.g. abstractions), so tasks
can easily use or reference them, e.g.:

```yml
- name: Set 'private' defaults for other tasks to use
  ansible.builtin.set_fact:
    _db_instance_identifier: >-
      {{
        [
          db_instance_identifier | default(None),
          instance_identifier | default(None),
          instance_id | default(None),
          id | default(None),
        ] | select | first
      }}
- name: Set 'private' defaults for only this task
  vars:
    _allocated_storage: "{{ allocated_storage | default(20) | int }}"
    _master_username: &master_username >-
      {{
        [
          master_username | default(None),
          username | default(None),
        ] | select | first
      }}
  amazon.aws.rds_instance:
    db_instance_identifier: "{{ _db_instance_identifier }}"
    master_username: *master_username
    allocated_storage: "{{ _allocated_storage }}"
    max_allocated_storage: "{{ max_allocated_storage | default(_allocated_storage) }}"
```

## Templating

Ansible leverages [Jinja2 templating], which can be used directly in tasks or through the `template` module.

All Jinja2's standard filters and tests can be used, with the addition of:

- specialized filters for selecting and transforming data
- tests for evaluating template expressions
- lookup plugins for retrieving data from external sources for use in templating

All templating happens **on the Ansible controller**, **before** the task is sent and executed on the target machine.

Updated [examples][examples  templating] are available.

```yaml
# Remove empty or false values from a list piping it to 'select()'.
# Returns ["string"].
- vars:
    list: ["", "string", 0, false]
  ansible.builtin.debug:
    var: list | select

# Remove only empty strings from a list 'reject()'ing them.
# Returns ["string", 0, false].
- vars:
    list: ["", "string", 0, false]
  ansible.builtin.debug:
    var: list | reject('match', '^$')

# Merge two lists.
# Returns ["a", "b", "c", "d"].
- vars:
    list1: ["a", "b"]
    list2: ["c", "d"]
  ansible.builtin.debug:
    var: list1 + list2

# Dedupe elements in a list.
# Returns ["a", "b"].
- vars:
    list: ["a", "b", "b", "a"]
  ansible.builtin.debug:
    var: list | unique

# Sort a list by version number (not lexicographically).
# Returns ['2.7.0', '2.8.0', '2.9.0', '2.10.0' '2.11.0'].
- vars:
    list: ['2.8.0', '2.11.0', '2.7.0', '2.10.0', '2.9.0']
  ansible.builtin.debug:
    var: list | community.general.version_sort

# Generate a random password.
# Returns a random string following the specifications.
- vars:
    password: "{{ lookup('password', '/dev/null length=32 chars=ascii_letters,digits,punctuation') }}"
  ansible.builtin.debug:
    var: password

# Hash a password.
# Returns a hash of the requested type.
- vars:
    password: abcd
    salt: "{{ lookup('community.general.random_string', special=false) }}"
  ansible.builtin.debug:
    var: password | password_hash('sha512', salt)

# Get a variable's type.
- ansible.builtin.debug:
    var: "'string' | type_debug"
```

### Tests

Return a boolean result.

```yaml
# Compare semver version numbers.
- ansible.builtin.debug:
    var: "'2.0.0-rc.1+build.123' is version('2.1.0-rc.2+build.423', 'ge', version_type='semver')"

# Find specific values in JSON objects.
- ansible.builtin.command: ssm-cli get-diagnostics --output 'json'
  become: true
  register: diagnostics
  failed_when: diagnostics.stdout | to_json | community.general.json_query('DiagnosticsOutput[*].Status=="Failed"')
```

### Loops

```yaml
# Get the values of some special variables.
# See the 'Further readings' section for the full list.
- ansible.builtin.debug:
    var: "{{ item }}"
  with_items: ["ansible_local", "playbook_dir", "role_path"]

# Fail when any of the given variables is an empty string.
# Returns the ones which are empty.
- when: lookup('vars', item) == ''
  ansible.builtin.fail:
    msg: "The {{ item }} variable is an empty string"
  loop:
    - variable1
    - variableN

# Iterate through nested loops.
- vars:
    middles:
      - 'middle1'
      - 'middle2'
  ansible.builtin.debug:
    msg: "{{ item[0] }}, {{ item[1] }}, {{ item[2] }}"
  with_nested:
    - ['outer1', 'outer2']
    - "{{ middles }}"
    - ['inner1', 'inner2']
```

## Use raw strings

Refer [Advanced playbook syntax].

Ansible uses the custom `!unsafe` data type to mark data as unsafe, and block Jinja2 templating in YAML.<br/>
This prevents abusing Jinja2 templates to execute arbitrary code on target machines, with the Ansible implementation
ensuring that unsafe values are never templated.

```yml
mypassword: !unsafe '234%234{435lkj{{lkjsdf'

vars:
  my_unsafe_variable: !unsafe 'unsafe % value'
  my_unsafe_array:
    - !unsafe 'unsafe element'
    - 'safe element'
  my_unsafe_hash:
    unsafe_key: !unsafe 'unsafe value'
```

The most common use cases include:

- Allowing passwords containing special characters like `{` or `%`.
- Allowing JSON arguments that look like templates but should not be templated.

The same result can be achieved by surrounding the Jinja2 code with the `{% raw %}` and `{% endraw %}` tags, though this
makes it less readable.

```yml
mypassword: "{% raw -%} 234%234{435lkj{{lkjsdf {%- endraw %}"
```

## Validation

### Assertions

```yaml
- ansible.builtin.assert:
    that:
      - install_method in supported_install_methods
      - external_url is ansible.builtin.url
    fail_msg: What to say if any of the above conditions fail
    success_msg: What to say if all of the above conditions succeed
```

## Asynchronous actions

Refer [Asynchronous actions and polling].

Useful for:

- Avoiding connection timeouts.
- Running **independent** tasks concurrently.

Tasks executing in asynchronous mode will return a Job ID that can be polled for information about that task.<br/>
Polling keeps the connection to the remote node open between polls.

Use the `async` keyword in playbook tasks.<br/>
Leaving it off makes tasks run synchronously, which is Ansible's default.

> [!warning]
> As of Ansible 2.3, `async` does **not** support check mode and tasks using it **will fail** when run in check mode.

Asynchronous tasks will create temporary async job cache files (in `~/.ansible_async/` by default).<br/>
When asynchronous tasks complete **with** polling enabled, the related temporary async job cache file is automatically
removed. This does **not** happen for tasks that do **not** use polling.

```sh
# Execute long running operations asynchronously in the background.
ansible 'all' -B '3600' -P '0' -a '/usr/bin/long_running_operation --do-stuff'   # no polling
ansible 'all' -B '1800' -P '60' -a '/usr/bin/long_running_operation --do-stuff'  # with polling

# Check on background jobs' status.
ansible 'web1.example.com' -m 'async_status' -a 'jid=488359678239.2844'
```

```yaml
---
- …
  tasks:
    - name: Simulate long running operation (15 sec), wait for up to 45 sec, poll every 5 sec
      ansible.builtin.command: /bin/sleep 15
      async: 45
      poll: 5
```

The default poll value is set by the `DEFAULT_POLL_INTERVAL` setting.<br/>
There is **no** default for `async`'s time limit.

Asynchronous playbook tasks **always** return changed.

### Run tasks in parallel

Use `async` with `poll` set to _0_.<br/>
When `poll` is _0_, Ansible starts the task, then immediately moves on to the next one with**out** waiting for a result
from the first.<br/>
Each asynchronous task runs until it either completes, fails, or times out (running longer than the value set for its
`async`). Playbook runs end with**out** checking back on asynchronous tasks.

```yaml
---
- tasks:
    - name: Simulate long running op (15 sec), allow to run for 45 sec, fire and forget
      ansible.builtin.command: /bin/sleep 15
      async: 45
      poll: 0
```

Operations requiring exclusive locks, such as YUM transactions, will make successive operations that require those same
files wait or fail.

Synchronize asynchronous tasks by registering them to obtain their job ID, and using it with the `async_status` module
in later tasks:

```yaml
- tasks:
    - name: Run an async task
      ansible.builtin.yum:
        name: docker-io
        state: present
      async: 1000
      poll: 0
      register: yum_sleeper
    - name: Check on an async task
      async_status:
        jid: "{{ yum_sleeper.ansible_job_id }}"
      register: job_result
      until: job_result.finished
      retries: 100
      delay: 10
```

## Error handling

### Using blocks

Refer [Blocks].

```yaml
- name: Error handling in blocks
  block:
    - name: This executes normally
      ansible.builtin.debug:
        msg: I execute normally
    - name: This errors out
      ansible.builtin.command: "/bin/false"
    - name: This never executes
      ansible.builtin.debug:
        msg: I never execute due to the above task failing
  rescue:
    - name: This executes if any errors arose in the block
      ansible.builtin.debug:
        msg: I caught an error and can do stuff here to fix it
  always:
    - name: This always executes
      ansible.builtin.debug:
        msg: I always execute
```

## Output formatting

> Introduced in Ansible 2.5

Change Ansible's output setting the stdout callback to `json` or `yaml`:

```sh
ANSIBLE_STDOUT_CALLBACK='yaml'
```

```ini
# ansible.cfg
[defaults]
stdout_callback = json
```

`yaml` will set tasks output only to be in the defined format:

```sh
$ ANSIBLE_STDOUT_CALLBACK='yaml' ansible-playbook --inventory='localhost,' 'localhost.configure.yml' -vv --check
PLAY [Configure localhost] *******************************************************************

TASK [Upgrade system packages] ***************************************************************
task path: /home/user/localhost.configure.yml:7
ok: [localhost] => changed=false
  cmd:
  - /usr/bin/zypper
  - --quiet
  - --non-interactive
  …
  update_cache: false
```

The `json` output format will be a single, long JSON file:

```sh
$ ANSIBLE_STDOUT_CALLBACK='json' ansible-playbook --inventory='localhost,' 'localhost.configure.yml' -vv --check
{
  "custom_stats": {},
  "global_custom_stats": {},
  "plays": [
    {
      "play": {
        …
        "name": "Configure localhost"
      },
      "tasks": [
        {
          "hosts": {
            "localhost": {
              "action": "community.general.zypper",
              "changed": false,
              …
              "update_cache": false
            }
          }
        }
      ]
    }
  ]
}
```

## Handlers

Using blocks and `import_tasks` for handlers tends to make the handlers inside them unreachable.

Instead of using blocks, give the same `listen` key to all involved handlers:

```diff
- - name: Block name
-   block:
-     - name: First task
-       …
-     - name: N-th task
-       …
+ - name: First task
+   listen: Block name
+   …
+ - name: N-th task
+   listen: Block name
+   …
```

Instead of using `import_tasks`, use `include_tasks`:

```diff
  - name: First task
-   import_tasks: tasks.yml
+   include_tasks: tasks.yml
```

Handlers **can** notify other handlers:

```yaml
- name: Configure Nginx
  ansible.builtin.copy: …
  notify: Restart Nginx

- name: Restart Nginx
  ansible.builtin.copy: …
```

## Roles

### Get roles

Roles can be either **created**:

```sh
ansible-galaxy init 'role-name'
```

or **installed** from [Galaxy]:

```yaml
---
# requirements.yml
collections:
  - community.docker
```

```sh
ansible-galaxy install 'mcereda.boinc_client'
ansible-galaxy install --roles-path 'path/to/roles' 'namespace.role'
ansible-galaxy install 'namespace.role,v1.0.0'
ansible-galaxy install 'git+https://github.com/namespace/role.git,commit-hash'
ansible-galaxy install -r 'requirements.yml'
```

### Assign roles

In playbooks:

```yaml
---
- hosts: all
  roles:
    - web_server
    - geerlingguy.postgresql
    - role: /custom/path/to/role
      vars:
        var1: value1
      tags: example
      message: some message
```

Roles are applied in order, and can**not** be parallelized at the time of writing.

### Role dependencies

Set them up in `role/meta/main.yml`:

```yaml
---
dependencies:
  - role: common
    vars:
      some_parameter: 3
  - role: postgres
    vars:
      dbname: blarg
      other_parameter: 12
```

and/or in `role/meta/requirements.yml`:

```yaml
---
collections:
  - community.dns
```

## Create custom filter plugins

See [Creating your own Ansible filter plugins].

## Execution environments

Container images that can be used as Ansible control nodes.<br/>
Refer [Getting started with Execution Environments].

Prefer using `ansible-navigator` to `ansible-runner` for local runs as the latter is a pain in the ass to use directly.

<details>
  <summary>Commands example</summary>

```sh
pip install 'ansible-builder' 'ansible-runner' 'ansible-navigator'
ansible-builder build --container-runtime 'docker' -t 'example-ee:latest' -f 'definition.yml'
ansible-runner -p 'test_play.yml' --process-isolation --container-image 'example-ee:latest'
ansible-navigator run 'test_play.yml' -i 'localhost,' --execution-environment-image 'example-ee:latest' \
  --mode 'stdout' --pull-policy 'missing' --container-options='--user=0'
```

</details>

### Build execution environments

Ansible Builder aids in the creation of Ansible Execution Environments.<br/>
Refer [Introduction to Ansible Builder] for how to build one.

Builders' `build` command defaults to using:

- `execution-environment.yml` or `execution-environment.yaml` as the definition file.
- `$PWD/context` as the directory to use for the build context.

<details>
  <summary><code>execution-environment.yml</code> example</summary>

Refer [Execution environment definition].

```yaml
---
version: 3

build_arg_defaults:
  ANSIBLE_GALAXY_CLI_COLLECTION_OPTS: '--pre'

dependencies:
  ansible_core:  # dedicated single-key dictionary
    package_pip: ansible-core==2.14.4
  ansible_runner:  # dedicated single-key dictionary
    package_pip: ansible-runner
  galaxy: requirements.yml
  python:  # pip packages
    - six
    - psutil
  system: bindep.txt
  exclude:
    python:
      - docker
    system:
      - python3-Cython

images:
  base_image:
    name: docker.io/redhat/ubi9:latest
    # Other available base images:
    #   - quay.io/rockylinux/rockylinux:9
    #   - quay.io/centos/centos:stream9
    #   - registry.fedoraproject.org/fedora:38
    #   - registry.redhat.io/ansible-automation-platform-23/ee-minimal-rhel8:latest
    #     (needs an account)

# Custom package manager path for the RHEL based images
# options:
#   package_manager_path: /usr/bin/microdnf

additional_build_files:
  - src: files/ansible.cfg
    dest: configs

additional_build_steps:
  prepend_base:
    - RUN echo This is a prepend base command!
    # Enable Non-default stream before packages provided by it can be installed. (optional)
    # - RUN $PKGMGR module enable postgresql:15 -y
    # - RUN $PKGMGR install -y postgresql
  prepend_galaxy:
    - COPY _build/configs/ansible.cfg /etc/ansible/ansible.cfg

  prepend_final: |
    RUN whoami
    RUN cat /etc/os-release
  append_final:
    - RUN echo This is a post-install command!
    - RUN ls -la /etc
```

</details>

<details>
  <summary><code>requirements.yml</code> example</summary>

```yaml
---
collections:
  - redhat.openshift
```

</details>

## Ansible Navigator

Refer [Ansible Navigator documentation].

Command-line tool and text-based user interface for creating, reviewing, running and troubleshooting Ansible content,
including inventories, playbooks, collections, documentation and container images (execution environments).

Settings for Navigator can be provided, in order of priority from **highest** to lowest:

1. On the command line.
1. Via environment variables.
1. By specifying them in [Navigator configuration files].<br/>
   Their **own** priority applies.

Environment variables **inside** Navigator's shell are set, in order of priority from **highest** to lowest:

- From _Passed_ environment variables, **if the passed variable is set**.
- From environment variables set from the CLI (with `--senv, --set-environment-variable`).
- From environment variables set in the evaluated config file (in
  `ansible-navigator.execution-environment.environment-variables.set`).

Volume mount paths **must** exist.

### Navigator configuration files

File name and path can be specified via an environment variable, or it can be placed in one of two default
directories.<br/>
It can be in the `JSON` or `YAML` format. JSON format files must end with the `.json` extension; YAML format files must
end with the `.yml` or `.yaml` extension.

Navigator checks the following and uses the **first** that matches:

1. The file name specified by the `ANSIBLE_NAVIGATOR_CONFIG` environment variable, if set.
1. The `ansible-navigator.<ext>` file in the current directory.<br/>
   This must **not** be a dotfile.
1. The `.ansible-navigator.<ext>` **dot**file in the user's home directory.

The current and home directories can have **only one** settings file **each**.<br/>
Should more than one settings file be found in either directory, the program **will** error out.

<details>
  <summary>File example</summary>

```yml
---
# refer <https://ansible.readthedocs.io/projects/navigator/settings/>.
# corresponds to `ansible-navigator --log-file='/dev/null' --container-options='--platform=linux/amd64'
#   --execution-environment-image='012345678901.dkr.ecr.eu-west-1.amazonaws.com/custom-ee' --pull-policy='missing'
#   --execution-environment-volume-mounts "$HOME/.aws:/runner/.aws:ro"
#   --pass-environment-variable 'ANSIBLE_VAULT_PASSWORD' --pass-environment-variable 'ANSIBLE_VAULT_PASSWORD_FILE'
#   --pass-environment-variable 'AWS_PROFILE' --pass-environment-variable 'AWS_REGION'
#   --pass-environment-variable 'AWS_DEFAULT_REGION' --set-environment-variable 'AWS_DEFAULT_REGION=eu-west-1'
#   run --enable-prompts …`
ansible-navigator:
  enable-prompts: true
  execution-environment:
    container-options:
      - --platform=linux/amd64
    image: 012345678901.dkr.ecr.eu-west-1.amazonaws.com/custom-ee
    pull:
      policy: missing
    volume-mounts:  # each must exist
      - src: ${HOME}/.aws
        dest: /runner/.aws
        options: ro
    environment-variables:  # pass from any > set from cli > set from conf
      pass:
        - ANSIBLE_VAULT_PASSWORD
        - ANSIBLE_VAULT_PASSWORD_FILE
        - AWS_DEFAULT_REGION
        - AWS_PROFILE
        - AWS_REGION
      set:
        AWS_DEFAULT_REGION: eu-west-1
  logging:
    file: /dev/null  # avoid leftovers
```

</details>

<details>
  <summary>Commands</summary>

```sh
# Review the configuration
ansible-navigator settings --effective

# Check the Execution Environment's shell environment
ansible-navigator … exec -- set | sort
ansible-navigator … exec -- printenv | sort
```

</details>

## Secrets management

Refer [Handling secrets in your Ansible playbooks].

Use **interactive prompts** to ask for values at runtime.

```yaml
---
- hosts: all
  gather_facts: false
  vars_prompt:
    - name: api_key
      prompt: Enter the API key
  tasks:
    - name: Ensure API key is present in config file
      ansible.builtin.lineinfile:
        path: /etc/app/configuration.ini
        line: "API_KEY={{ api_key }}"
```

Use [Ansible Vault] for automated execution when one does **not** require using specific secrets or password managers.

### Hiding sensitive values in verbose runs

Refer [Hide sensitive data in Ansible verbose logs].

### Ansible Vault

Refer [Protecting sensitive data with Ansible Vault], [Ansible Vault tutorial] and [Ansible Vault with AWX].

Vault encrypts variables and files **at rest** and allows for their use in playbooks and roles.<br/>
It does **not** prevent tasks to print out data **in use**. See the
[`no_log`](https://docs.ansible.com/ansible/latest/reference_appendices/faq.html#keep-secret-data) attribute for hiding
sensible values.

Protected data **will** require one or more passwords to encrypt and decrypt.<br/>
If storing vault passwords in third-party tools, one will need them need to allow for non-interactive access.

Create and view protected data by using the `ansible-vault` command.

Provide the Vault's password:

- By using command line options.<br/>
  Make ansible ask for it using `‑‑ask‑vault‑pass`, or provide a file containing it with `--vault-password-file`:

  ```sh
  ansible … --ask-vault-pass
  ansible-playbook … --vault-password-file 'password_file.txt'
  ```

- By exporting the `ANSIBLE_VAULT_PASSWORD` or `ANSIBLE_VAULT_PASSWORD_FILE` environment variables to specify the
  password itself or the location of the password file, respectively:

  ```sh
  ANSIBLE_VAULT_PASSWORD_FILE='password_file.txt' ansible …
  export ANSIBLE_VAULT_PASSWORD='abracadabra' ; ansible-playbook …
  ```

- By using the `ansible.cfg` config file to either always prompt for the password, or to specify the default location of
  the password file:

  ```ini
  [defaults]
  vault_password_file = password_file.txt
  ; ask_vault_pass = True
  ```

Should the password file be executable, Ansible will execute it, then use its output as the password for Vault.<br/>
This works well to integrate with CLI-capable password managers:

```sh
# File 'password_file.sh'

# Gopass
gopass show -o 'ansible/vault'

# Bitwarden CLI
# bw login --check >'/dev/null' && bw get password 'ansible vault'
```

Vault passwords can be any string, and there is currently no special command to create one.<br/>
One must provide the/a Vault password **every time one encrypts and/or decrypts data** with Vault.<br/>
If using multiple Vault passwords, one can differentiate between them by means of vault IDs.

> By default, Vault IDs only label protected content to remind one which password one used to encrypt it. Ansible will
> **not** check that the vault ID in the header of any encrypted content matches the vault ID one provides when using
> that content, and will try and decrypt the data with the password one provides.<br/>
> Force this check by setting the `DEFAULT_VAULT_ID_MATCH` config option.

Vault can only encrypt variables and files.<br/>
Encrypted content is marked in playbook and roles with the `!vault` tag. This tells Ansible and YAML that the content
needs to be decrypted. Content created with `--vault-id` also contains the vault ID's label in the mark.

Encrypted **variables** allow for mixed plaintext and encrypted content, even inline, in plays or roles.<br/>
One **cannot** _rekey_ encrypted variables.<br/>
To encrypt tasks or other content, one must encrypt the entire file.

Input files are encrypted in-place unless one specifies the output files in the command.

<details style="padding-left: 1em">
  <summary>Encrypt and use variables</summary>

1. Encrypt the variable's value:

   ```sh
   $ ansible-vault encrypt_string --name 'command_output' 'somethingNobodyShouldKnow'
   New Vault password:
   Confirm New Vault password:
   Encryption successful
   command_output: !vault |
             $ANSIBLE_VAULT;1.1;AES256
             34306534613939316131303430653733633961623931363032633933393039373764356464623461
             3463353332623466623661363831303836396165323238660a353137363562393161396566386565
             35616662336536613365386164353439616232643131306534353264346635373566313630613261
             3531373034333830640a353138306463653533366432623438343266623930396238313763643836
             66646237336338353866306361316233326535333236363136613263346631633836

   $ ansible-vault encrypt_string --name 'command_output' 'somethingNobodyShouldKnow' \
       --vault-password-file 'password_file.txt'
   Encryption successful
   command_output: !vault |
             $ANSIBLE_VAULT;1.1;AES256
             31373465393164316666663963643163313032623233356634313038333662653061623936383838
             6166636433313438613338373438343130633766656535390a353338373261393931316533303837
             64363736383163643238336565363936303434393931386131383463336539306466636231633131
             6432396337366333350a356338623630626161333666373831313966633038343133316532383562
             61303538333031333861313733383363656531613333356364363432343361393636
   ```

1. Use the output as the value:

   ```yaml
   - name: Configure credential 'Gitlab container registry PAT'
     tags:
       - container_registry
       - gitlab
     awx.awx.credential:
       organization: Private
       name: Gitlab container registry PAT
       credential_type: Container Registry
       inputs:
         host: gitlab.example.org:5050
         username: awx  # or anything, really
         password: !vault |
           $ANSIBLE_VAULT;1.1;AES256
           34306534613939316131303430653733633961623931363032633933393039373764356464623461
           3463353332623466623661363831303836396165323238660a353137363562393161396566386565
           35616662336536613365386164353439616232643131306534353264346635373566313630613261
           3531373034333830640a353138306463653533366432623438343266623930396238313763643836
           66646237336338353866306361316233326535333236363136613263346631633836
         verify_ssl: false
       update_secrets: false
   ```

1. Require the play execution to ask for the password used during encryption:

   ```sh
   ansible-playbook -i 'localhost,' -c 'local' -Dvvv 'playbook.yml' -t 'container_registry' --ask-vault-pass
   ansible-playbook … --vault-password-file 'password_file.txt'
   ```

</details>

<details style="padding: 0 0 1em 1em">
  <summary>Encrypt and use existing files</summary>

1. Encrypt the file:

   ```sh
   # Input files are encrypted in place unless output files are specified
   $ ansible-vault encrypt 'ssh.key'
   New Vault password:
   Confirm New Vault password:
   Encryption successful

   $ ansible-vault encrypt --output 'ssh_key.enc' '.ssh/id_rsa' --vault-password-file 'password_file.txt'
   Encryption successful
   ```

1. Use the file normally:

   ```yaml
   - name: Test value is read correctly
     tags: debug
     ansible.builtin.debug:
       msg: "{{ lookup('file', 'ssh_key.enc') }}"
   ```

1. Require the play execution to ask for the password used during encryption:

   ```sh
   ansible-playbook -i 'localhost,' -c 'local' -Dvvv 'playbook.yml' -t 'container_registry' --ask-vault-pass
   ansible-playbook … --vault-password-file 'password_file.txt'
   ```

</details>

Decrypt files with `ansible-vault decrypt 'path/to/file'`.<br/>
Input files are decrypted in place unless one specifies the output files in the command.

<details style="padding: 0 0 1em 1em">
  <summary>Decrypt files</summary>

```sh
$ ansible-vault decrypt 'ssh.key'
New Vault password:
Confirm New Vault password:
Decryption successful

$ ansible-vault decrypt --output '.ssh/id_rsa' --vault-password-file 'password_file.txt' 'ssh.key'
Decryption successful
```

</details>

One can quickly view the content of encrypted files with `ansible-vault view 'path/to/file'`:

<details style="padding: 0 0 1em 1em">
  <summary>View encrypted files' content</summary>

```sh
$ cat 'ssh.key.pub'
$ANSIBLE_VAULT;1.1;AES256
38623265623763366431646435646634363136373831323464356130383432356266616461323730
6436396161613934356339323731336130383064386464610a373664326235376336333736306563
62366635646565633833336638616434353935313632323733326634356366666439316336353030
6635353335653034340a613330323565366365346638343464623036396134626537643064653437
36653734373839306135306165326464633231383236663735646465643332383332626564643038
64363531383430393834373764633564383537326430303038383661656134383631306336633539
33343166386135663537656262343734383339383363343736633965393262666133623932653732
63613034393964333865626532636332393964396463613131356534623433353065313661383461
37646635336433376132393766333761306162366666346634323166353630633036

$ ansible-vault view 'ssh.key.pub'
Vault password:
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFIw4vv6LYg3P7bfgrR5I4k/0123456789abcdefghIL me@example.org

$ ansible-vault view 'ssh.key.pub' --vault-password-file 'password_file.txt'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFIw4vv6LYg3P7bfgrR5I4k/0123456789abcdefghIL me@example.org
```

</details>

Or even edit their content with `ansible-vault edit 'path/to/file'`.

## Best practices

- Tag **all** tasks somehow.
- Define tasks so that playbook runs will **not** fail just because one task depends on another.
- Provide ways to **manually** feed values to dependent tasks so that runs can start from there or only use tagged
  tasks, e.g. by using variables that can be overridden in the command line.
- Consider using `blocks` to group tasks logically.
- Keep debugging messages but set them to run only at higher verbosity:

  ```yaml
  tasks:
    - debug:
        msg: "I always display!"
    - debug:
        msg: "I only display with ansible-playbook -vvv+"
        verbosity: 3
  ```

- When **replacing** resources, if possible, make sure the replacement is set correctly **before** deleting the
  original.
- If using other systems to maintain a canonical list of systems in one's infrastructure, consider using dynamic
  inventories.

## Troubleshooting

### ERROR: Ansible could not initialize the preferred locale: unsupported locale setting

`ansible-core` requires the locale to have `UTF-8` encoding [since 2.14.0][ansible v2.14 CHANGELOG]:

> ansible - At startup the filesystem encoding and locale are checked to verify they are UTF-8. If not, the process
> exits with an error reporting the errant encoding.

```sh
LANG='C.UTF-8' ansible …
```

### Print all known variables

Print the special variable `vars` as a task:

```yaml
- name: Debug all variables
  ansible.builtin.debug: var=vars
```

### Force notified handlers to run at a specific point

Use the `meta` plugin with the `flush_handlers` option:

```yaml
- name: Force all notified handlers to run at this point, not waiting for normal sync points
  ansible.builtin.meta: flush_handlers
```

### Time tasks execution

Add `profile_tasks` the list of enable callbacks.

Choose one or more options:

- Add it to `callbacks_enabled` in the `[defaults]` section of Ansible's configuration file:

  ```ini
  [defaults]
  callbacks_enabled = profile_tasks  # or ansible.posix.profile_tasks
  ```

- Set the `ANSIBLE_CALLBACKS_ENABLED` environment variable:

  ```sh
  export ANSIBLE_CALLBACKS_ENABLED='profile_tasks'
  ```

### Run specific tasks even in check mode

Add the `check_mode: false` pair to the task:

```yaml
- name: this task will make changes to the system even in check mode
  check_mode: false
  ansible.builtin.command: /something/to/run --even-in-check-mode
```

### Dry-run only specific tasks

Add the `check_mode: true` pair to the task:

```yaml
- name: This task will always run under check mode and not change the system
  check_mode: true
  ansible.builtin.lineinfile:
    line: "important file"
    dest: /path/to/file.conf
    state: present
```

### Set up recursive permissions on a directory so that directories are set to 755 and files to 644

Use the special `X` mode setting in the `file` plugin:

```yaml
- name: Fix files and directories' permissions
  ansible.builtin.file:
    dest: /path/to/some/dir
    mode: u=rwX,g=rX,o=rX
    recurse: yes
```

### Only run a task when another has a specific result

When a task executes, it also stores the two special values `changed` and `failed` in its results.<br/>
One can use those as conditions to execute the next ones:

```yaml
- name: Trigger task
  ansible.builtin.command: any
  register: trigger_task
  ignore_errors: true

- name: Run only on change
  when: trigger_task.changed
  ansible.builtin.debug: msg="The trigger task changed"

- name: Run only on failure
  when: trigger_task.failed
  ansible.builtin.debug: msg="The trigger task failed"
```

Alternatively, you can use special checks built for this:

```yaml
- name: Run only on success
  when: trigger_task is succeeded
  ansible.builtin.debug: msg="The trigger task succeeded"

- name: Run only on change
  when: trigger_task is changed
  ansible.builtin.debug: msg="The trigger task changed"

- name: Run only on failure
  when: trigger_task is failed
  ansible.builtin.debug: msg="The trigger task failed"

- name: Run only on skip
  when: trigger_task is skipped
  ansible.builtin.debug: msg="The trigger task skipped"
```

### Define when a task changed or failed

This lets you avoid using `ignore_errors`.

Use the `changed_when` and `failed_when` attributes to define your own conditions:

```yaml
- name: Task with custom results
  ansible.builtin.command: any
  register: result
  changed_when:
    - result.rc == 2
    - result.stderr | regex_search('things changed')
  failed_when:
    - result.rc != 0
    - not (result.stderr | regex_search('all good'))
```

### Set environment variables for a play, role or task

Environment variables can be set at a play, block, or task level using the `environment` keyword:

```yaml
- name: Use environment variables for a task
  environment:
    HTTP_PROXY: http://example.proxy
  ansible.builtin.command: curl ifconfig.io
```

The `environment` keyword does **not** affect Ansible itself or its configuration settings, the environment for other
users, or the execution of other plugins like lookups and filters.<br/>
Variables set with `environment` do **not** automatically become Ansible facts, even when set at the play level.

### Set variables to the value of environment variables

Use the `lookup()` plugin with the `env` option:

```yaml
- name: Use a local environment variable
  ansible.builtin.debug: msg="HOME={{ lookup('env', 'HOME') }}"
```

### Check if a list contains an item and fail otherwise

```yaml
- name: Check if a list contains an item and fail otherwise
  when: item not in list
  ansible.builtin.fail: msg="item not in list"
```

### Define different values for `true`/`false`/`null`

Create a test and define two values: the first will be returned when the test returns `true`, the second will be
returned when the test returns `false` (Ansible 1.9+):

```yaml
{{ (ansible_pkg_mgr == 'zypper') | ternary('gnu_parallel', 'parallel') }}
```

Since Ansible 2.8 you can define a third value to be returned when the test returns `null`:

```yaml
{{ autoscaling_enabled | ternary(true, false, omit) }}
```

### Force a task or play to use a specific Python interpreter

Just set it in the Play's or Task's variables:

```yaml
vars:
  ansible_python_interpreter: /usr/local/bin/python3.9
```

### Provide a template file content inline

Use the `ansible.builtin.copy` instead of `ansible.builtin.template`:

```yaml
- name: Configure knockd
  ansible.builtin.copy:
    dest: /etc/knockd.conf
    content: |
      [options]
        UseSyslog
```

### Python breaks in OS X

Root Cause:

> Mac OS High Sierra and later versions have restricted multithreading for improved security.<br/>
> Apple has defined some rules on what is allowed and not is not after forking processes, and have also added
> `async-signal-safety` to a limited number of APIs.

Solution:

Disable fork initialization safety features as shown in
[Why Ansible and Python fork break on macOS High Sierra+ and how to solve]\:

```sh
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```

### Load files' content into variables

For **local** files, use lookups:

```yaml
user_data: "{{ lookup('file', 'path/to/file') }}"
```

For **remote** files, use the [`slurp` module][slurp]:

```yaml
- ansible.builtin.slurp:
    src: "{{ user_data_file }}"
  register: slurped_user_data
- ansible.builtin.set_fact:
    user_data: "{{ slurped_user_data.content | ansible.builtin.b64decode }}"
```

The contents are presented as base64 string. The decode is needed.

### Only run a task when explicitly requested

Leverage the [`never` tag][special tags: always and never] to never execute the task unless requested by using the
`--tags 'never'` option:

```yaml
- tags: never
  ansible.builtin.debug:
    msg: …
```

Conversely, one can achieve the opposite by using the `always` tag and the `--skip 'always'` option:

```yaml
- tags: always
  ansible.builtin.command: …
```

### Using AWS' SSM with Ansible fails with error _Failed to create temporary directory_

Message example:

> ```plaintext
> fatal: [i-4ccab452bb7743336]: UNREACHABLE! => {
>   "changed": false,
>   "msg": "Failed to create temporary directory. In some cases, you may have been able to authenticate and did not have permissions on the target directory. Consider changing the remote tmp path in ansible.cfg to a path rooted in \"/tmp\", for more error information use -vvv. Failed command was: ( umask 77 && mkdir -p \"` echo \u001b]0;@ip-192-168-42-42:/usr/bin\u0007/home/centos/.ansible/tmp `\"&& mkdir \"` echo \u001b]0;@ip-192-168-42-42:/usr/bin\u0007/home/centos/.ansible/tmp/ansible-tmp-1708603630.2433128-49665-225488680421418 `\" && echo ansible-tmp-1708603630.2433128-49665-225488680421418=\"` echo \u001b]0;@ip-192-168-42-42:/usr/bin\u0007/home/centos/.ansible/tmp/ansible-tmp-1708603630.2433128-49665-225488680421418 `\" ), exited with result 1, stdout output: \u001b]0;@ip-192-168-42-42:/usr/bin\u0007bash: @ip-192-168-42-42:/usr/bin/home/centos/.ansible/tmp: No such file or directory\r\r\nmkdir: cannot create directory '0': Permission denied\r\r",
>   "unreachable": true
> }
> ```

Root cause:

By default, SSM starts sessions in the `/usr/bin` directory.

Solution:

Explicitly set Ansible's temporary directory to a folder the remote user can write to.<br/>
See [Integrate with AWS SSM].

### Future feature annotations is not defined

Refer [Newer versions of Ansible don't work with RHEL 8].

Error message example:

> ```plaintext
> SyntaxError: future feature annotations is not defined
> ```

Solution: use a version of `ansible-core` lower than 2.17.

### Boolean variables given from the CLI are treated as strings

Refer [defining variables at runtime].<br/>
Also see [How can I pass variable to ansible playbook in the command line?].

> Values passed in using the `key=value` syntax are interpreted as strings.<br/>
> Use the JSON format if you need to pass non-string values such as Booleans, integers, floats, lists, and so on.

So yeah. Use the JSON format.

```sh
ansible … --extra-vars '{ "i_wasted_30_mins_debugging_a_boolean_string": true }'
```

Another _better (?)_ solution in playbooks/roles would be to sanitize the input as a pre-flight task.

## Further readings

- [Configuration]
- [Templating]
- [Examples]
- [Roles]
- [Tests]
- [Special variables]
- [Collections index]<br/>
  Each also shows the list of connection types, filters, modules, etc it adds.
- [Automating Helm using Ansible]
- [Edit .ini file in other servers using Ansible PlayBook]
- [Yes and No, True and False]
- [Galaxy]
- [Ansible Galaxy user guide]
- [Windows playbook example]
- [Special tags: `always` and `never`][special tags: always and never]
- [Integrate with AWS SSM]
- [Mitogen for Ansible]
- [Debugging tasks]
- [AWX]
- [Introduction to Ansible Builder]
- [Ansible Navigator documentation]
- [Ansible Runner]
- [Using variables]

### Sources

- [Removing empty values from a list and assigning it to a new list]
- [Human-Readable Output Format]
- [How to append to lists]
- [Check if a list contains an item in ansible]
- [Working with versions]
- [How to install SSHpass on Mac]
- [Include task only if file exists]
- [Unique filter of list in jinja2]
- [Only do something if another action changed]
- [How to recursively set directory and file permissions]
- [Is it possible to use inline templates?]
- [How to set up and use Python virtual environments for Ansible]
- [Merging two dictionaries by key in Ansible]
- [Creating your own Ansible filter plugins]
- [Why Ansible and Python fork break on macOS High Sierra+ and how to solve]
- [Ansible: set variable to file content]
- [How can I hide skipped tasks output in Ansible]
- [Ansible roles: basics, creating & using]
- [Developing and Testing Ansible Roles with Molecule and Podman - Part 1]
- [How to get an arbitrary remote user's home directory in Ansible?]
- [6 ways to speed up Ansible playbook execution]
- [How to speed up Ansible playbooks drastically?]
- [Easy things you can do to speed up ansible]
- [What is the exact list of Ansible setup min?]
- [Setup module source code]
- [8 ways to speed up your Ansible playbooks]
- [Blocks]
- [How to work with lists and dictionaries in Ansible]
- [Handling secrets in your Ansible playbooks]
- [Ansible - how to remove an item from a list?]
- [Looping over lists inside of a dict]
- [Newer versions of Ansible don't work with RHEL 8]
- [Running your Ansible playbooks in parallel and other strategies]
- [Execution environment definition]
- [Protecting sensitive data with Ansible vault]
- [Ansible Vault tutorial]
- [Ansible Vault with AWX]
- [Asynchronous actions and polling]
- [Patterns: targeting hosts and groups]
- [How to use ansible with S3 - Ansible aws_s3 examples]
- [How to run Ansible with_fileglob in alphabetical order?]
- [Ansible v2.14 CHANGELOG]
- [How can I pass variable to ansible playbook in the command line?]
- [Ansible Map Examples - Filter List and Dictionaries]
- [Advanced playbook syntax]
- [Ansible delegation madness: delegate_to and variable substitution]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[ansible vault]: #ansible-vault
[navigator configuration files]: #navigator-configuration-files

<!-- Knowledge base -->
[awx]: awx.md
[integrate with aws ssm]: cloud%20computing/aws/ssm.md#integrate-with-ansible
[Rundeck]: rundeck.md
[Semaphore UI]: semaphoreui.md

<!-- Files -->
[examples]: ../examples/ansible/
[examples  templating]: ../examples/ansible/templating.yml

<!-- Upstream -->
[8 ways to speed up your Ansible playbooks]: https://www.redhat.com/sysadmin/faster-ansible-playbook-execution
[Advanced playbook syntax]: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_advanced_syntax.html
[ansible galaxy user guide]: https://docs.ansible.com/ansible/latest/galaxy/user_guide.html
[ansible navigator documentation]: https://ansible.readthedocs.io/projects/navigator/
[ansible runner]: https://ansible.readthedocs.io/projects/runner/en/stable/
[ansible v2.14 changelog]: https://github.com/ansible/ansible/blob/7bb078bd740fba8ad43cc69e18fc8aeb4719180a/changelogs/CHANGELOG-v2.14.rst#id11
[async_dir not properly expanding variables]: https://github.com/ansible/ansible/issues/85370
[asynchronous actions and polling]: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_async.html
[automating helm using ansible]: https://www.ansible.com/blog/automating-helm-using-ansible
[Blocks]: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_blocks.html
[collections index]: https://docs.ansible.com/ansible/latest/collections/index.html
[configuration]: https://docs.ansible.com/ansible/latest/reference_appendices/config.html
[debugging tasks]: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_debugger.html
[defining variables at runtime]: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#defining-variables-at-runtime
[developing and testing ansible roles with molecule and podman - part 1]: https://www.ansible.com/blog/developing-and-testing-ansible-roles-with-molecule-and-podman-part-1/
[Execution environment definition]: https://ansible.readthedocs.io/projects/builder/en/stable/definition/
[Galaxy  sivel.toiletwater]: https://galaxy.ansible.com/ui/repo/published/sivel/toiletwater/
[Galaxy]: https://galaxy.ansible.com/
[Getting started with Execution Environments]: https://docs.ansible.com/ansible/latest/getting_started_ee/index.html
[Introduction to Ansible Builder]: https://www.ansible.com/blog/introduction-to-ansible-builder/
[patterns: targeting hosts and groups]: https://docs.ansible.com/ansible/latest/inventory_guide/intro_patterns.html
[protecting sensitive data with ansible vault]: https://docs.ansible.com/ansible/latest/vault_guide/index.html
[roles]: https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html
[setup module source code]: https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/setup.py
[setup module]: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/setup_module.html
[slurp]: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/slurp_module.html
[special tags: always and never]: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_tags.html#special-tags-always-and-never
[special variables]: https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html
[templating]: https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html
[tests]: https://docs.ansible.com/ansible/latest/user_guide/playbooks_tests.html
[using variables]: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html

<!-- Others -->
[6 ways to speed up ansible playbook execution]: https://wearenotch.com/speed-up-ansible-playbook-execution/
[ansible - how to remove an item from a list?]: https://stackoverflow.com/questions/40927792/ansible-how-to-remove-an-item-from-a-list#40927834
[Ansible delegation madness: delegate_to and variable substitution]: https://makk.es/blog/ansible-delegation-madness/
[Ansible Map Examples - Filter List and Dictionaries]: https://www.middlewareinventory.com/blog/ansible-map/
[ansible roles: basics, creating & using]: https://spacelift.io/blog/ansible-roles
[ansible vault tutorial]: https://piyops.com/ansible-vault-tutorial
[ansible vault with awx]: https://medium.com/t%C3%BCrk-telekom-bulut-teknolojileri/ansible-vault-with-awx-80b603617798
[ansible: set variable to file content]: https://stackoverflow.com/questions/24003880/ansible-set-variable-to-file-content
[check if a list contains an item in ansible]: https://stackoverflow.com/questions/28080145/check-if-a-list-contains-an-item-in-ansible/28084746
[Creating your own Ansible filter plugins]: https://www.dasblinkenlichten.com/creating-ansible-filter-plugins/
[Easy things you can do to speed up ansible]: https://mayeu.me/post/easy-things-you-can-do-to-speed-up-ansible/
[edit .ini file in other servers using ansible playbook]: https://syslint.com/blog/tutorial/edit-ini-file-in-other-servers-using-ansible-playbook/
[Handling secrets in your Ansible playbooks]: https://www.redhat.com/sysadmin/ansible-playbooks-secrets
[Hide sensitive data in Ansible verbose logs]: https://harshanu.space/en/tech/ansible-redact/
[how can i hide skipped tasks output in ansible]: https://stackoverflow.com/questions/39189549/how-can-i-hide-skipped-tasks-output-in-ansible#76147924
[how can i pass variable to ansible playbook in the command line?]: https://stackoverflow.com/questions/30662069/how-can-i-pass-variable-to-ansible-playbook-in-the-command-line#30662156
[how to append to lists]: https://blog.crisp.se/2016/10/20/maxwenzin/how-to-append-to-lists-in-ansible
[how to get an arbitrary remote user's home directory in ansible?]: https://stackoverflow.com/questions/33343215/how-to-get-an-arbitrary-remote-users-home-directory-in-ansible#45447488
[how to install sshpass on mac]: https://stackoverflow.com/questions/32255660/how-to-install-sshpass-on-mac/62623099#62623099
[how to recursively set directory and file permissions]: https://superuser.com/questions/1024677/ansible-how-to-recursively-set-directory-and-file-permissions#1317715
[how to run ansible with_fileglob in alphabetical order?]: https://stackoverflow.com/questions/59162054/how-to-run-ansible-with-fileglob-in-alpabetical-order#59162339
[how to set up and use python virtual environments for ansible]: https://www.redhat.com/sysadmin/python-venv-ansible
[How to speed up Ansible playbooks drastically?]: https://www.linkedin.com/pulse/how-speed-up-ansible-playbooks-drastically-lionel-gurret
[how to use ansible with s3 - ansible aws_s3 examples]: https://www.middlewareinventory.com/blog/ansible-aws_s3-example/
[how to work with lists and dictionaries in ansible]: https://www.redhat.com/sysadmin/ansible-lists-dictionaries-yaml
[human-readable output format]: https://www.shellhacks.com/ansible-human-readable-output-format/
[include task only if file exists]: https://stackoverflow.com/questions/28119521/ansible-include-task-only-if-file-exists#comment118578470_62289639
[is it possible to use inline templates?]: https://stackoverflow.com/questions/33768690/is-it-possible-to-use-inline-templates#33783423
[jinja2 templating]: https://jinja.palletsprojects.com/en/stable/templates/
[looping over lists inside of a dict]: https://www.reddit.com/r/ansible/comments/1b28dtm/looping_over_lists_inside_of_a_dict/
[merging two dictionaries by key in ansible]: https://serverfault.com/questions/1084157/merging-two-dictionaries-by-key-in-ansible#1084164
[mitogen for ansible]: https://mitogen.networkgenomics.com/ansible_detailed.html
[newer versions of ansible don't work with rhel 8]: https://www.jeffgeerling.com/blog/2024/newer-versions-ansible-dont-work-rhel-8
[only do something if another action changed]: https://raymii.org/s/tutorials/Ansible_-_Only-do-something-if-another-action-changed.html
[removing empty values from a list and assigning it to a new list]: https://stackoverflow.com/questions/60525961/ansible-removing-empty-values-from-a-list-and-assigning-it-to-a-new-list#60526774
[running your ansible playbooks in parallel and other strategies]: https://toptechtips.github.io/2023-06-26-ansible-parallel/
[unique filter of list in jinja2]: https://stackoverflow.com/questions/44329598/unique-filter-of-list-in-jinja2
[what is the exact list of ansible setup min?]: https://stackoverflow.com/questions/71060833/what-is-the-exact-list-of-ansible-setup-min#71061125
[Why Ansible and Python fork break on macOS High Sierra+ and how to solve]: https://ansiblepilot.medium.com/why-ansible-and-python-fork-break-on-macos-high-sierra-and-how-to-solve-d11540cd2a1b
[windows playbook example]: https://geekflare.com/ansible-playbook-windows-example/
[working with versions]: https://docs.ansible.com/ansible/latest/collections/community/general/docsite/filter_guide_working_with_versions.html
[yes and no, true and false]: https://chronicler.tech/red-hat-ansible-yes-no-and/
[zuul]: https://zuul-ci.org/
