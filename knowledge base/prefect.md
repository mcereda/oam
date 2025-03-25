# Prefect

Workflow orchestration framework for building data pipelines in Python.

Workflow activity is tracked and can be monitored from a Prefect (self-hosted or cloud-managed).

Allows building and scheduling workflows in pure Python, to then run them anywhere.<br/>
Designed to handle retries, dependencies, branching logic, dynamic workflows, modern infrastructure, and data pipelines'
complexity.<br/>
Handles automatic state tracking, failure handling, real-time monitoring, and more.

1. [TL;DR](#tldr)
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
# Start.
prefect server start
docker run -d -p '4200:4200' 'prefecthq/prefect:3-latest' -- prefect server start --host '0.0.0.0'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

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
