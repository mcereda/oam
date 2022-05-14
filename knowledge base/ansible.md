# Ansible

## TL;DR

```sh
# Install.
pip3 install --user ansible && port install sshpass   # darwin
sudo pamac install ansible sshpass                    # manjaro linux

# Show hosts' ansible facts.
ansible -i hostfile -m setup all
ansible -i host1,hostn, -m setup host1 -u remote-user
ansible -i localhost, -c local -km setup localhost

# Check the syntax of a playbook.
# This will *not* execute the plays inside it.
ansible-playbook path/to/playbook.yml --syntax-check

# Execute a playbook.
ansible-playbook path/to/playbook.yml -i hosts.list
ansible-playbook path/to/playbook.yml -i host1,host2,hostn, -l hosts,list
ansible-playbook path/to/playbook.yml -i host1,host2,other, -l hosts-pattern

# Show what changes (with details) a play whould apply to the local machine.
ansible-playbook path/to/playbook.yml -i localhost, -c local -vvC

# Only execute tasks with specific tags.
ansible-playbook path/to/playbook.yml --tags "configuration,packages"

# Avoid executing tasks with specific tags.
ansible-playbook path/to/playbook.yml --skip-tags "system,user"

# Check what tasks will be executed.
ansible-playbook example.yml --list-tasks
ansible-playbook example.yml --list-tasks --tags "configuration,packages"
ansible-playbook example.yml --list-tasks --skip-tags "system,user"

# List roles installed from Galaxy.
ansible-galaxy list

# Install roles from Galaxy.
ansible-galaxy install namespace.role
ansible-galaxy install --roles-path ~/ansible-roles namespace.role
ansible-galaxy install namespace.role,v1.0.0
ansible-galaxy install git+https://github.com/namespace/role.git,commit-hash
ansible-galaxy install -r requirements.yml

# Remove roles installed from Galaxy.
ansible-galaxy remove namespace.role
```

## Templating

```yaml
- name: >-
    Get the values of some special variables.
    See https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html
    for the full list.
  ansible.builtin.debug:
    var: "{{ item }}"
  with_items: ["ansible_local", "playbook_dir", "role_path"]

- name: >-
    Remove empty or false values from a list piping it to 'select()'.
    Returns ["string"] from ["", "string", 0, false].
  vars:
    list: ["", "string", 0, false]
  ansible.builtin.debug:
    var: list | select

- name: >-
    Remove only empty strings from a list 'reject()'ing them.
    Returns ["string", 0, false] from ["", "string", 0, false].
  vars:
    list: ["", "string", 0, false]
  ansible.builtin.debug:
    var: list | reject('match', '^$')

- name: >-
    Merge two lists.
    Returns ["a", "b", "c", "d"] from ["a", "b"] and ["c", "d"].
  vars:
    list1: ["a", "b"]
    list2: ["c", "d"]
  ansible.builtin.debug:
    var: list1 + list2

- name: >-
    Dedupe elements in a list.
    Returns ["a", "b"] from ["a", "b", "b", "a"].
  vars:
    list: ["a", "b", "b", "a"]
  ansible.builtin.debug:
    var: list | unique

- name: >-
    Sort list by version number (not lexicographically).
    Returns ['2.7.0', '2.8.0', '2.9.0',, '2.10.0' '2.11.0'] from ['2.8.0', '2.11.0', '2.7.0', '2.10.0', '2.9.0']
  vars:
    list: ['2.8.0', '2.11.0', '2.7.0', '2.10.0', '2.9.0']
  ansible.builtin.debug:
    var: list | community.general.version_sort

- name: >-
    Compare a semver version number.
    Returns a boolean result.
  ansible.builtin.debug:
    var: "'2.0.0-rc.1+build.123' is version('2.1.0-rc.2+build.423', 'ge', version_type='semver')"

- name: >-
    Generate a random password.
    Returns a random string following the specifications.
  vars:
    password: "{{ lookup('password', '/dev/null length=32 chars=ascii_letters,digits,punctuation') }}"
  ansible.builtin.debug:
    var: password

- name: >-
    Hash a password.
    Returns a hash of the requested type.
  vars:
    password: abcd
    salt: "{{ lookup('community.general.random_string', special=false) }}"
  ansible.builtin.debug:
    var: password | password_hash('sha512', salt)

- name: Get a variable's type.
  ansible.builtin.debug:
    var: "'string' | type_debug"
```

## Loops

```yaml
- name: >-
    Fail when any of the given variables is an empty string.
    Returns the ones which are.
  when: lookup('vars', item) == ''
  ansible.builtin.fail:
    msg: "The {{ item }} variable is an empty string"
  loop:
    - variable1
    - variableN

- name: Nested loop.
  vars:
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
ansible-galaxy init role-name
```

or **installed** from [Ansible Galaxy]:

```yaml
---
# requirements.yml
collections:
  - community.docker
```

```sh
ansible-galaxy install mcereda.boinc_client
ansible-galaxy install --roles-path ~/ansible-roles namespace.role
ansible-galaxy install namespace.role,v1.0.0
ansible-galaxy install git+https://github.com/namespace/role.git,0b7cd353c0250e87a26e0499e59e7fd265cc2f25
ansible-galaxy install -r requirements.yml
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
ANSIBLE_STDOUT_CALLBACK=yaml
```

```ini
# ansible.cfg
[defaults]
stdout_callback = json
```

`yaml` will set tasks output only to be in the defined format:

```text
$ ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook --inventory=localhost.localdomain, ansible/localhost.configure.yml -vv --check
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

```text
$ ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook --inventory=localhost.localdomain, ansible/localhost.configure.yml -vv --check
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
- name: This task will always run under checkmode and not change the system
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
  when: trigger_task succeeded
  ansible.builtin.debug: msg="The trigger task changed"

- name: Run only on change
  when: trigger_task changed
  ansible.builtin.debug: msg="The trigger task changed"

- name: Run only on failure
  when: trigger_task failed
  ansible.builtin.debug: msg="The trigger task failed"

- name: Run only on skip
  when: trigger_task skipped
  ansible.builtin.debug: msg="The trigger task failed"
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

## Further readings

- [Roles]
- [Tests]
- [Special variables]
- [Automating Helm using Ansible]
- [Edit .ini file in other servers using Ansible PlayBook]
- [Yes and No, True and False]
- [Ansible Galaxy user guide]
- [Windows playbook example]

[ansible galaxy user guide]: https://docs.ansible.com/ansible/latest/galaxy/user_guide.html
[automating helm using ansible]: https://www.ansible.com/blog/automating-helm-using-ansible
[roles]: https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html
[special variables]: https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html
[tests]: https://docs.ansible.com/ansible/latest/user_guide/playbooks_tests.html

[edit .ini file in other servers using ansible playbook]: https://syslint.com/blog/tutorial/edit-ini-file-in-other-servers-using-ansible-playbook/
[windows playbook example]: https://geekflare.com/ansible-playbook-windows-example/
[yes and no, true and false]: https://chronicler.tech/red-hat-ansible-yes-no-and/

## Sources

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

[check if a list contains an item in ansible]: https://stackoverflow.com/questions/28080145/check-if-a-list-contains-an-item-in-ansible/28084746
[how to append to lists]: https://blog.crisp.se/2016/10/20/maxwenzin/how-to-append-to-lists-in-ansible
[how to install sshpass on mac]: https://stackoverflow.com/questions/32255660/how-to-install-sshpass-on-mac/62623099#62623099
[how to recursively set directory and file permissions]: https://superuser.com/questions/1024677/ansible-how-to-recursively-set-directory-and-file-permissions#1317715
[human-readable output format]: https://www.shellhacks.com/ansible-human-readable-output-format/
[include task only if file exists]: https://stackoverflow.com/questions/28119521/ansible-include-task-only-if-file-exists#comment118578470_62289639
[only do something if another action changed]: https://raymii.org/s/tutorials/Ansible_-_Only-do-something-if-another-action-changed.html
[removing empty values from a list and assigning it to a new list]: https://stackoverflow.com/questions/60525961/ansible-removing-empty-values-from-a-list-and-assigning-it-to-a-new-list#60526774
[unique filter of list in jinja2]: https://stackoverflow.com/questions/44329598/unique-filter-of-list-in-jinja2
[working with versions]: https://docs.ansible.com/ansible/latest/collections/community/general/docsite/filter_guide_working_with_versions.html

<!-- Other references -->

[ansible galaxy]: https://galaxy.ansible.com/
