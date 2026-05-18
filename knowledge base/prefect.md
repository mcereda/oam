# Prefect

Workflow orchestration framework for building data pipelines in Python.

Workflow activity is tracked and can be monitored from a Prefect (self-hosted or cloud-managed).

Allows building and scheduling workflows in pure Python, to then run them anywhere.<br/>
Designed to handle retries, dependencies, branching logic, dynamic workflows, modern infrastructure, and data pipelines'
complexity.<br/>
Handles automatic state tracking, failure handling, real-time monitoring, and more.

1. [TL;DR](#tldr)
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
[codebase]: https://github.com/PrefectHQ/Prefect
[documentation]: https://docs.prefect.io/v3/get-started/index
[website]: https://www.prefect.io/

<!-- Others -->
