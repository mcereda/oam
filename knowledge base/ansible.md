# Ansible

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
1. [Templating](#templating)
   1. [Tests](#tests)
   1. [Loops](#loops)
1. [Roles](#roles)
   1. [Get roles](#get-roles)
   1. [Assign roles](#assign-roles)
   1. [Role dependencies](#role-dependencies)
1. [Output formatting](#output-formatting)
1. [Create custom filter plugins](#create-custom-filter-plugins)
1. [Troubleshooting](#troubleshooting)
   1. [Print all known variables](#print-all-known-variables)
   1. [Force notified handlers to run at a specific point](#force-notified-handlers-to-run-at-a-specific-point)
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
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Install.
pip3 install --user 'ansible'
brew install 'ansible' 'sshpass'         # darwin
sudo pamac install 'ansible' 'sshpass'   # manjaro linux

# Generate example configuration files with entries disabled.
ansible-config init --disabled > 'ansible.cfg'
ansible-config init --disabled -t 'all' > 'ansible.cfg'

# Show hosts' ansible facts.
ansible -i 'path/to/hosts/file' -m 'setup' all
ansible -i 'host1,hostN,' -m 'setup' 'host1' -u 'remote-user'
ansible -i 'localhost,' -c 'local' -km 'setup' 'localhost'

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

# Show what changes (with details) a play would apply to the local machine.
ansible-playbook 'path/to/playbook.yml' -i 'localhost,' -c 'local' -vvC

# Only execute tasks with specific tags.
ansible-playbook 'path/to/playbook.yml' --tags 'configuration,packages'

# Avoid executing tasks with specific tags.
ansible-playbook 'path/to/playbook.yml' --skip-tags 'system,user'

# Check what tasks will be executed.
ansible-playbook 'path/to/playbook.yml' --list-tasks
ansible-playbook … --list-tasks --tags 'configuration,packages'
ansible-playbook … --list-tasks --skip-tags 'system,user'

# Debug playbooks.
ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-playbook …

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

<details>
  <summary>Galaxy collections and roles worth a check</summary>

| ID                                             | Type       | Description           |
| ---------------------------------------------- | ---------- | --------------------- |
| [sivel.toiletwater][galaxy  sivel.toiletwater] | collection | Extra filters, mostly |

</details>

## Configuration

Ansible can be configured using INI files named `ansible.cfg`, environment variables, command-line options, playbook
keywords, and variables.

The `ansible-config` utility allows to see all the configuration settings available, their defaults, how to set them and
where their current value comes from.

Ansible will process the following list and use the first file found; all the other files are ignored even if existing:

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
                            …
                            "action": "community.general.zypper",
                            "changed": false,
                            …
                            "update_cache": false
                        }
                    }
                    …
…
}
```

## Create custom filter plugins

See [Creating your own Ansible filter plugins].

## Troubleshooting

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
{{ (ansible_pkg_mgr == 'zypper') | ternary('gnu_parallel', 'parallel')) }}
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

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[integrate with aws ssm]: cloud%20computing/aws/ssm.md#integrate-with-ansible

<!-- Files -->
[examples]: ../examples/ansible/
[examples  templating]: ../examples/ansible/templating.yml

<!-- Upstream -->
[ansible galaxy user guide]: https://docs.ansible.com/ansible/latest/galaxy/user_guide.html
[automating helm using ansible]: https://www.ansible.com/blog/automating-helm-using-ansible
[collections index]: https://docs.ansible.com/ansible/latest/collections/index.html
[configuration]: https://docs.ansible.com/ansible/latest/reference_appendices/config.html
[developing and testing ansible roles with molecule and podman - part 1]: https://www.ansible.com/blog/developing-and-testing-ansible-roles-with-molecule-and-podman-part-1/
[galaxy  sivel.toiletwater]: https://galaxy.ansible.com/ui/repo/published/sivel/toiletwater/
[galaxy]: https://galaxy.ansible.com/
[roles]: https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html
[slurp]: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/slurp_module.html
[special tags: always and never]: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_tags.html#special-tags-always-and-never
[special variables]: https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html
[templating]: https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html
[tests]: https://docs.ansible.com/ansible/latest/user_guide/playbooks_tests.html

<!-- Others -->
[ansible roles: basics, creating & using]: https://spacelift.io/blog/ansible-roles
[ansible: set variable to file content]: https://stackoverflow.com/questions/24003880/ansible-set-variable-to-file-content
[check if a list contains an item in ansible]: https://stackoverflow.com/questions/28080145/check-if-a-list-contains-an-item-in-ansible/28084746
[creating your own ansible filter plugins]: https://www.dasblinkenlichten.com/creating-ansible-filter-plugins/
[edit .ini file in other servers using ansible playbook]: https://syslint.com/blog/tutorial/edit-ini-file-in-other-servers-using-ansible-playbook/
[how can i hide skipped tasks output in ansible]: https://stackoverflow.com/questions/39189549/how-can-i-hide-skipped-tasks-output-in-ansible#76147924
[how to append to lists]: https://blog.crisp.se/2016/10/20/maxwenzin/how-to-append-to-lists-in-ansible
[how to get an arbitrary remote user's home directory in ansible?]: https://stackoverflow.com/questions/33343215/how-to-get-an-arbitrary-remote-users-home-directory-in-ansible#45447488
[how to install sshpass on mac]: https://stackoverflow.com/questions/32255660/how-to-install-sshpass-on-mac/62623099#62623099
[how to recursively set directory and file permissions]: https://superuser.com/questions/1024677/ansible-how-to-recursively-set-directory-and-file-permissions#1317715
[how to set up and use python virtual environments for ansible]: https://www.redhat.com/sysadmin/python-venv-ansible
[human-readable output format]: https://www.shellhacks.com/ansible-human-readable-output-format/
[include task only if file exists]: https://stackoverflow.com/questions/28119521/ansible-include-task-only-if-file-exists#comment118578470_62289639
[is it possible to use inline templates?]: https://stackoverflow.com/questions/33768690/is-it-possible-to-use-inline-templates#33783423
[jinja2 templating]: https://jinja.palletsprojects.com/en/3.1.x/templates/
[merging two dictionaries by key in ansible]: https://serverfault.com/questions/1084157/merging-two-dictionaries-by-key-in-ansible#1084164
[only do something if another action changed]: https://raymii.org/s/tutorials/Ansible_-_Only-do-something-if-another-action-changed.html
[removing empty values from a list and assigning it to a new list]: https://stackoverflow.com/questions/60525961/ansible-removing-empty-values-from-a-list-and-assigning-it-to-a-new-list#60526774
[unique filter of list in jinja2]: https://stackoverflow.com/questions/44329598/unique-filter-of-list-in-jinja2
[why ansible and python fork break on macos high sierra+ and how to solve]: https://ansiblepilot.medium.com/why-ansible-and-python-fork-break-on-macos-high-sierra-and-how-to-solve-d11540cd2a1b
[windows playbook example]: https://geekflare.com/ansible-playbook-windows-example/
[working with versions]: https://docs.ansible.com/ansible/latest/collections/community/general/docsite/filter_guide_working_with_versions.html
[yes and no, true and false]: https://chronicler.tech/red-hat-ansible-yes-no-and/
