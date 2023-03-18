# Ansible

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
1. [Templating](#templating)
   1. [Tests](#tests)
   1. [Loops](#loops)
1. [Roles](#roles)
   1. [Get roles](#get-roles)
   1. [Role dependencies](#role-dependencies)
1. [Output formatting](#output-formatting)
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
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Install.
pip3 install --user 'ansible' && port install 'sshpass'   # darwin
sudo pamac install 'ansible' 'sshpass'                    # manjaro linux

# Generate an example configuration file with all entries disabled.
ansible-config init --disabled > 'ansible.cfg'
ansible-config init --disabled -t 'all' > 'ansible.cfg'

# Show hosts' ansible facts.
ansible -i 'path/to/hosts/file' -m 'setup' all
ansible -i 'host1,hostN,' -m 'setup' 'host1' -u 'remote-user'
ansible -i 'localhost,' -c 'local' -km 'setup' 'localhost'

# Check the syntax of a playbook.
# This will *not* execute the plays inside it.
ansible-playbook 'path/to/playbook.yml' --syntax-check

# Execute a playbook.
ansible-playbook 'path/to/playbook.yml' -i 'hosts.list'
ansible-playbook … -i 'host1,host2,hostN,' -l 'hosts,list'
ansible-playbook … -i 'host1,host2,other,' -l 'hosts-pattern'

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

# List roles installed from Galaxy.
ansible-galaxy list

# Install roles from Galaxy.
ansible-galaxy install 'namespace.role'
ansible-galaxy install --roles-path 'path/to/ansible/roles' 'namespace.role'
ansible-galaxy install 'namespace.role,v1.0.0'
ansible-galaxy install 'git+https://github.com/namespace/role.git,commit-hash'
ansible-galaxy install -r 'requirements.yml'

# Remove roles installed from Galaxy.
ansible-galaxy remove 'namespace.role'
```

## Configuration

Ansible can be configured using INI files named `ansible.cfg`, environment variables, command-line options, playbook keywords, and variables.

The `ansible-config` utility allows to see all the configuration settings available, their defaults, how to set them and where their current value comes from.

Ansible will process the following list and use the first file found; all the other files are ignored even if existing:

1. the `ANSIBLE_CONFIG` environment variable;
1. the `ansible.cfg` file in the current directory;
1. the `~/.ansible.cfg` file in the user's home directory;
1. the `/etc/ansible/ansible.cfg` file.

One can generate a fully commented-out example of the `ansible.cfg` file:

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

Updated [examples] are available.

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

### Role dependencies

```yaml
---
# role/meta/main.yml
dependencies:
  - role: common
    vars:
      some_parameter: 3
  - role: postgres
    vars:
      dbname: blarg
      other_parameter: 12
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
$ ANSIBLE_STDOUT_CALLBACK='yaml' ansible-playbook --inventory='localhost.localdomain,' 'localhost.configure.yml' -vv --check
PLAY [Configure localhost] *******************************************************************

TASK [Upgrade system packages] ***************************************************************
task path: /home/user/localhost.configure.yml:7
ok: [localhost.localdomain] => changed=false
  cmd:
  - /usr/bin/zypper
  - --quiet
  - --non-interactive
  …
  update_cache: false
```

The `json` output format will be a single, long JSON file:

```sh
$ ANSIBLE_STDOUT_CALLBACK='json' ansible-playbook --inventory='localhost.localdomain,' 'localhost.configure.yml' -vv --check
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
                        "localhost.localdomain": {
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

When a task executes, it also stores the two special values `changed` and `failed` in its results. You can use those as conditions to execute the next ones:

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

The `environment` keyword does not affect Ansible itself or its configuration settings, the environment for other users, or the execution of other plugins like lookups and filters; variables set with `environment` do not automatically become Ansible facts, even when set at the play level.

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

Create a test and define two values: the first will be returned when the test returns `true`, the second will be returned when the test returns `false` (Ansible 1.9+):

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

## Further readings

- [Configuration]
- [Templating]
- [Templating examples]
- [Roles]
- [Tests]
- [Special variables]
- [Automating Helm using Ansible]
- [Edit .ini file in other servers using Ansible PlayBook]
- [Yes and No, True and False]
- [Galaxy]
- [Ansible Galaxy user guide]
- [Windows playbook example]

## Sources

All the references in the [further readings] section, plus the following:

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

<!-- project's references -->
[ansible galaxy user guide]: https://docs.ansible.com/ansible/latest/galaxy/user_guide.html
[automating helm using ansible]: https://www.ansible.com/blog/automating-helm-using-ansible
[configuration]: https://docs.ansible.com/ansible/latest/reference_appendices/config.html
[galaxy]: https://galaxy.ansible.com/
[roles]: https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html
[special variables]: https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html
[templating]: https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html
[tests]: https://docs.ansible.com/ansible/latest/user_guide/playbooks_tests.html

<!-- internal references -->
[further readings]: #further-readings
[templating examples]: ../examples/ansible/templating.yml

<!-- external references -->
[check if a list contains an item in ansible]: https://stackoverflow.com/questions/28080145/check-if-a-list-contains-an-item-in-ansible/28084746
[edit .ini file in other servers using ansible playbook]: https://syslint.com/blog/tutorial/edit-ini-file-in-other-servers-using-ansible-playbook/
[how to append to lists]: https://blog.crisp.se/2016/10/20/maxwenzin/how-to-append-to-lists-in-ansible
[how to install sshpass on mac]: https://stackoverflow.com/questions/32255660/how-to-install-sshpass-on-mac/62623099#62623099
[how to recursively set directory and file permissions]: https://superuser.com/questions/1024677/ansible-how-to-recursively-set-directory-and-file-permissions#1317715
[human-readable output format]: https://www.shellhacks.com/ansible-human-readable-output-format/
[include task only if file exists]: https://stackoverflow.com/questions/28119521/ansible-include-task-only-if-file-exists#comment118578470_62289639
[is it possible to use inline templates?]: https://stackoverflow.com/questions/33768690/is-it-possible-to-use-inline-templates#33783423
[jinja2 templating]: https://jinja.palletsprojects.com/en/3.1.x/templates/
[only do something if another action changed]: https://raymii.org/s/tutorials/Ansible_-_Only-do-something-if-another-action-changed.html
[removing empty values from a list and assigning it to a new list]: https://stackoverflow.com/questions/60525961/ansible-removing-empty-values-from-a-list-and-assigning-it-to-a-new-list#60526774
[unique filter of list in jinja2]: https://stackoverflow.com/questions/44329598/unique-filter-of-list-in-jinja2
[windows playbook example]: https://geekflare.com/ansible-playbook-windows-example/
[working with versions]: https://docs.ansible.com/ansible/latest/collections/community/general/docsite/filter_guide_working_with_versions.html
[yes and no, true and false]: https://chronicler.tech/red-hat-ansible-yes-no-and/
