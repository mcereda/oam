# Prefect

Workflow orchestration framework for building data pipelines in Python.

Workflow activity is tracked and can be monitored from a Prefect (self-hosted or cloud-managed).

Allows building and scheduling workflows in pure Python, to then run them anywhere.<br/>
Designed to handle retries, dependencies, branching logic, dynamic workflows, modern infrastructure, and data pipelines'
complexity.<br/>
Handles automatic state tracking, failure handling, real-time monitoring, and more.

1. [TL;DR](#tldr)
1. [Setup](#setup)
   1. [Self-hosted server](#self-hosted-server)
1. [Flows and tasks](#flows-and-tasks)
   1. [Transactions](#transactions)
1. [Deploying flows](#deploying-flows)
1. [Automations](#automations)
1. [Secrets and credentials](#secrets-and-credentials)
1. [Limiting concurrent jobs on a work pool](#limiting-concurrent-jobs-on-a-work-pool)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Install.
docker pull 'prefecthq/prefect:3-latest'
pip install --upgrade 'prefect'

# Check installation.
prefect version
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Check the version.
prefect version

# Start the server.
prefect server start
docker run -d -p '4200:4200' 'prefecthq/prefect:3-latest' -- prefect server start --host '0.0.0.0'

# Schedule workflows.
prefect schedule 'main/my_first_deployment' '0 8 * * *'

# Cancel running workflows.
prefect flow-run cancel 'a55a4804-9e3c-4042-8b59-b3b6b7618736'

# List all work queues.
prefect work-queue ls

# Pause work queues.
prefect work-queue pause 'queue-name'

# List deployments.
prefect deployment ls

# Pause deployment schedules.
prefect deployment pause 'deployment-name'

# List work pools.
prefect work-pool ls

# Pause work pools.
prefect work-pool pause 'pool-name'

# Run a deployment.
prefect deployment run 'flow-name/deployment-name'

# Manage variables.
prefect variable set 'var-name' 'value'
prefect variable get 'var-name'
prefect variable ls
prefect variable unset 'var-name'

# Login to the cloud instance.
prefect cloud login

# List cloud workspaces.
prefect cloud workspace ls

# Set a default cloud workspace.
prefect cloud workspace set --workspace "some/workspace"
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Setup

### Self-hosted server

`prefect server start` from the [TL;DR](#tldr) runs a minimal instance on SQLite.<br/>
Production workloads require PostgreSQL (with the `pg_trgm` extension). Multi-worker setups also need Redis.

<details>
  <summary>Production setup (PostgreSQL)</summary>

```sh
# Set the database connection.
# Note: the driver must be asyncpg, not the default psycopg2.
prefect config set PREFECT_SERVER_DATABASE_CONNECTION_URL='postgresql+asyncpg://user:pass@host:5432/prefect'

# Run database migrations.
prefect server database upgrade -y

# Start the server.
prefect server start --host '0.0.0.0'
```

Point clients at the server:

```sh
prefect config set 'PREFECT_API_URL=http://<server-host>:4200/api'
```

</details>

<details>
  <summary>Multi-worker mode</summary>

SQLite does **not** support multi-worker due to database locking. PostgreSQL and Redis are **both** required.

```sh
prefect config set PREFECT_SERVER_EVENTS_MESSAGING_BROKER='prefect_redis.messaging'
prefect config set PREFECT_SERVER_EVENTS_MESSAGING_CACHE='prefect_redis.messaging'
prefect config set PREFECT_SERVER_EVENTS_CAUSAL_ORDERING='prefect_redis.ordering'
prefect config set PREFECT_SERVER_CONCURRENCY_LEASE_STORAGE='prefect_redis.lease_storage'
```

</details>

When starting a worker with `--type`, it auto-creates the named pool if it does not exist. In that case, it does so
with a bare default template (no cluster, subnets, nor roles).<br/>
Flows scheduled against a non-configured pool appear normal, but fail at **launch** time (not at _scheduling_ time).

Fetch the default template as a starting point for customization:

```sh
prefect work-pool get-default-base-job-template --type 'ecs' --file 'ecs-base-template.json'
```

When running behind a reverse proxy, set `PREFECT_UI_API_URL` to the externally reachable URL. Without it, the browser
UI inherits the container-local `PREFECT_API_URL` and cannot connect.

## Flows and tasks

The `@flow` decorator turns a function into an orchestrated workflow. It automates state tracking, validates typed
parameters, and allows configuring retries:

```python
from prefect import flow

@flow(retries=3, retry_delay_seconds=5, timeout_seconds=300, log_prints=True)
def my_pipeline(name: str = "world"):
    print(f"Hello {name}!")
```

Flows can call other flows (creating parent-child relationships) and contain tasks.<br/>
Nested flows block parents until completion. Async nested flows can run concurrently via `asyncio.gather`.

The `@task` decorator defines the smallest unit of orchestrated work.<br/>
Tasks are cacheable, retryable, and support transactional semantics.

Tasks can execute in the following modes:

- **Direct**: `result = my_task(args)` blocks until done.
- **Concurrent**: `future = my_task.submit(args)` returns a `PrefectFuture`; resolve with `future.result()`.<br/>
  Use `.map()` for parallel iteration over collections.
- **Background**: `my_task.delay(args)` dispatches to a separate [task worker][Background tasks] (similar to
  Celery).<br/>
  Requires `prefect task serve` or `serve(my_task)` from `prefect.task_worker`.

### Transactions

Prefect 3 groups tasks into atomic [transactions][Transactions]. If any part fails, staged subtransactions roll back
automatically via `on_rollback` hooks:

```python
from prefect import flow
from prefect.transactions import transaction

@flow
def pipeline():
    with transaction():
        write_data()
        validate()  # failure here rolls back write_data
```

## Deploying flows

Create [deployments][Deployments concept], depending on infrastructure needs, using any of the following methods:

- `flow.serve()` runs flows on **static** infrastructure. Best for simple setups.<br/>
  A long-running process monitors for work, and executes runs in subprocesses.

  <details style='padding: 0 0 1rem 1rem'>

  ```python
  if __name__ == "__main__":
      my_flow.serve(
          name="my-deployment",
          tags=["production"],
          parameters={"name": "world"},
          interval=60,
      )
  ```

  </details>

- `flow.deploy()` provisions **dynamic** infrastructure via [work pools][Work pools].<br/>
  By default, it builds and pushes a Docker image.

  <details style='padding: 0 0 1rem 1rem'>

  ```python
  if __name__ == "__main__":
      my_flow.deploy(
          name="my-deployment",
          work_pool_name="docker-pool",
          image="my-registry/my-image:latest",
      )
  ```

  </details>

- `prefect deploy` is for **declarative** CLI approach. Walks through the creation of a `prefect.yaml` with build, push,
  and pull steps.

Use `serve` for simple scheduling on persistent infrastructure. Prefer `deploy` when flows need isolated, dynamically
provisioned environments.

Deployments support their own concurrency limit via `concurrency_limit` and a `collision_strategy` (`ENQUEUE` to queue
excess runs, `CANCEL_NEW` to reject them), independent of the work pool concurrency covered below.

## Automations

Refer to [Automations].

Execute actions automatically when trigger conditions are met (e.g. a flow run state changes, metrics' thresholds,
custom events), or by the _absence_ of expected events (e.g. a flow stuck running beyond 30 minutes).

Actions include cancelling/suspending flow runs, pausing deployment schedules or work pools, sending notifications
(Slack, Teams, email, webhooks), and chaining other automations.<br/>
Notification templates support Jinja2 (`{{ flow_run.name }}`, `{{ flow_run|ui_url }}`).

## Secrets and credentials

Refer to [How to store secrets].

Blocks referenced in deployment pull steps are resolved by the workers/agents at **runtime**. They fetch them fresh
**each and every time** a flow runs.

Blocks can refer to secrets in AWS Secrets Manager.<br/>
The [`prefect-aws`][prefect-aws] integration provides an `AwsSecret` block type, which makes agents read from Secrets
Manager using the [boto3 credential chain] and prevents the need for explicit AWS credentials to be stored in Prefect.

The `git_clone` pull step supports specifying credentials via:

- _Credentials_ block references, e.g. `credentials: "{{ prefect.blocks.gitlab-credentials.name }}"`.

  > [!important]
  > Some Prefect 2.x versions might hit a
  > [known issue][Prefect deployment git clone step not working with Gitlab/Github Credential blocks] where
  > `git_clone` does not properly resolve `GitLabCredentials` blocks.<br/>
  > In this case, use _access token_ type blocks referencing a `Secret` or `AwsSecret` block instead.

- _Access token_ block references, e.g. `access_token: "{{ prefect.blocks.aws-secret.name }}"`.

  <details style='padding: 0 0 1rem 1rem'>

  ```yml
  pull:
    - prefect.deployments.steps.git_clone:
        repository: https://gitlab.example.org/some/project
        access_token: "{{ prefect.blocks.aws-secret.some-gitlab-project-token }}"
  ```

  </details>

- Chained shell script.<br/>
  This means running a `run_shell_script` step before `git_clone`. The shell script fetches the token from an external
  secret store, and passes it as output.

  <details style='padding: 0 0 1rem 1rem'>

  ```yml
  pull:
    - prefect.deployments.steps.run_shell_script:
        script: |
          aws secretsmanager get-secret-value \
            --secret-id some/gitlab/project/token \
            --query SecretString --output text
        stream_output: false
    - prefect.deployments.steps.git_clone:
        repository: https://gitlab.example.org/some/project
        access_token: "{{ run_shell_script.stdout }}"
  ```

  </details>

## Limiting concurrent jobs on a work pool

One can cap concurrency on multiple layers (pool > queue > worker).<br/>
This model allows to set a hard infrastructure ceiling at the pool level, and then use queue concurrency for
prioritization within that ceiling. The levels stack so that the **most restrictive** one wins:

- The **work _pool_** concurrency limit caps the entire pool across all workers:

  <details style='padding: 0 0 1rem 1rem'>

  ```sh
  prefect work-pool set-concurrency-limit 'some-pool' '3'
  ```

  </details>

- The **worker** limit caps how many flow runs a single worker process handles:

  <details style='padding: 0 0 1rem 1rem'>

  ```sh
  prefect worker start -p 'some-pool' --limit '3'
  ```

  </details>

- The **work _queue_** concurrency limit caps a specific queue within the pool:

  <details style='padding: 0 0 1rem 1rem'>

  ```sh
  prefect work-queue set-concurrency-limit 'some-queue' -p 'some-pool' '3'
  ```

  </details>

For a single agent pulling from PaaS and running via Docker, the work _pool_ concurrency limit is the simplest
lever. It takes effect immediately for new runs, while allows in-progress runs to continue.<br/>
Set it via CLI or in the Prefect Cloud UI under _Work Pools_ > some pool > _Concurrency Limit_.

Cap locally per-worker processes using the `--limit` flag on the worker.<br/>
If you only have one worker, pool-level and worker-level limits are functionally equivalent. The pool-level limit can
be changed at runtime without restarting the worker.

## Further readings

- [Website]
- [Codebase]
- [Prefect MCP server] for connecting AI assistants (Claude Code, Cursor) to a Prefect environment

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[Automations]: https://docs.prefect.io/v3/concepts/automations
[Background tasks]: https://docs.prefect.io/v3/how-to-guides/workflows/run-background-tasks
[Codebase]: https://github.com/PrefectHQ/Prefect
[Deployments concept]: https://docs.prefect.io/v3/concepts/deployments
[Documentation]: https://docs.prefect.io/v3/get-started/index
[How to store secrets]: https://docs.prefect.io/v3/develop/secrets
[Prefect deployment git clone step not working with Gitlab/Github Credential blocks]: https://github.com/PrefectHQ/prefect/issues/11279
[Prefect MCP server]: https://docs.prefect.io/v3/how-to-guides/ai/use-prefect-mcp-server
[prefect-aws]: https://docs.prefect.io/integrations/prefect-aws/index
[Transactions]: https://docs.prefect.io/v3/develop/transactions
[Website]: https://www.prefect.io/
[Work pools]: https://docs.prefect.io/v3/concepts/work-pools

<!-- Others -->
[boto3 credential chain]: https://boto3.amazonaws.com/v1/documentation/api/latest/guide/credentials.html#configuring-credentials
