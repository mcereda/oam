# Semaphore UI

Modern UI for Ansible, Terraform/OpenTofu and Bash.

1. [TL;DR](#tldr)
1. [Runners](#runners)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

_Projects_ are independent environments where all activities occur.

_Templates_ define how to run code.<br/>
What is run depends on their type.

_Tasks_ are instances of template runs.<br/>
Create tasks from templates. Status and logs are available once tasks start running.

The _key store_ stores credentials for accessing remote repositories and hosts, sudo credentials, and Ansible vault
passwords.

_Inventories_ are files containing lists of hosts Ansible will run plays against.<br/>
They are effectively just Ansible inventories.

Each inventory also must have at least one credential tied to it.<br/>
The user credential is required, and is what Ansible uses to log into hosts for that inventory.<br/>
Sudo credentials are used for escalating privileges on those hosts.

A user credential must be either a username with a login, or SSH keys configured in the Key Store.

_Environments_ store additional variables for inventories and must be stored in JSON format.<br/>
All templates require an environment to be defined, even if empty.

_Integrations_ allow establishing interaction between Semaphore and external services.

Supports MySQL, PostgreSQL and BoltDB (an embedded key/value database) for storing its data.

<details>
  <summary>Setup</summary>

```sh
sudo snap install 'semaphore'
docker run -d --name 'semaphore' -p 3000:3000 \
  -e SEMAPHORE_DB_DIALECT='bolt' \
  -e SEMAPHORE_ADMIN='admin' -e SEMAPHORE_ADMIN_PASSWORD='changeme' \
  -e SEMAPHORE_ADMIN_NAME='Admin' -e SEMAPHORE_ADMIN_EMAIL='admin@localhost' \
  'semaphoreui/semaphore:v2.10.22'

wget 'https://github.com/semaphoreui/semaphore/releases/download/v2.9.58/semaphore_2.9.44_linux_amd64.deb' \
&& sudo dpkg -i 'semaphore_2.9.44_linux_amd64.deb'
```

Refer the [Docker container configurator] for all available environment variables.

</details>

<details>
  <summary>Usage</summary>

```sh
sudo snap stop 'semaphore'
sudo semaphore user add --admin --login 'john' --name 'John' --email 'john1996@gmail.com' --password '12345'
sudo snap start 'semaphore'
sudo snap services 'semaphore'
sudo snap get 'semaphore'
sudo snap refresh 'semaphore'

semaphore setup
semaphore server --config='./config.json'
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
docker compose run --rm --user 'root' 'semaphore' chown -Rv 'semaphore' '/etc/semaphore' '/var/lib/semaphore'
```

</details>

## Runners

Can be used to run tasks on separate servers from the one hosting Semaphore.<br/>
They operate like GitLab or GitHub Actions runners would:

1. One launches a runner on a separate host, specifying the Semaphore server's address and an authentication token.
1. The runner connects to Semaphore and signals its readiness to accept tasks.
1. When a new task appears, Semaphore provides all the necessary information to the runner.
1. The runner clones the repository and runs the task.
1. The runner sends the task execution results back to Semaphore.

The runner app comes as part of Semaphore.

It is launched with the following command:

```sh
semaphore runner --config './config.json'
```

The runner's configuration file must contain a runner section with the following parameters:

```json
{
  "runner": {
    "registration_token": "***",
    "config_file": "path/to/the/file/where/runner/saves/service/information",
    "api_url": "http://<semaphore_host>:<semaphore_port>/api",
    "max_parallel_tasks": 10
  }
}
```

Allow the Semaphore server to work with runners by setting the following parameters in its configuration file:

```json
{
  "use_remote_runner": true,
  "runner_registration_token": "***"
}
```

## Further readings

- [Website]
- [Main repository]
- [Docker compose file]

### Sources

- [Docker container configurator]
- [Runners]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
[docker compose file]: ../containers/semaphoreui/docker-compose.yml

<!-- Upstream -->
[docker container configurator]: https://semaphoreui.com/install/docker/
[main repository]: https://github.com/semaphoreui/semaphore
[runners]: https://docs.semaphoreui.com/administration-guide/runners
[website]: https://semaphoreui.com/

<!-- Others -->
