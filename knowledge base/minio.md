# MinIO

High-performance, S3 compatible object storage.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

Suggested deployment mode by use case:

| Use Case               | Deployment Mode     | Min Hardware         | Failure Tolerance            | Scalability           |
| ---------------------- | ------------------- | -------------------- | ---------------------------- | --------------------- |
| Development or testing | Standalone Single   | 1 server, 1 drive    | None                         | None                  |
| Small Production       | Standalone Erasure  | 1 server, 4-8 drives | N/2 drives                   | Vertical only         |
| High Availability      | Distributed         | 4 servers, 8+ drives | N/2 drives + server failures | Horizontal + Vertical |
| Multi-Tenant           | Multiple Instances  | Varies               | Per-tenant                   | Per-tenant            |
| Enterprise/Cloud       | Kubernetes/Operator | Varies               | Configurable                 | Full automation       |

</details>

<details>
  <summary>Usage</summary>

```sh
# Start the server.
minio server '/data'
minio server --address ':9000' "/data"{1...12}
minio server "http://server"{1...4}"/data"{1...4}
MINIO_ROOT_USER=tenant1_access_key MINIO_ROOT_PASSWORD=tenant1_secret_key minio server --address ':9001' '/data/tenant1'
MINIO_ROOT_USER=tenant2_access_key MINIO_ROOT_PASSWORD=tenant2_secret_key minio server --address ':9002' \
  'http://192.168.10.'{1...4}'/data/tenant2'

# Show information about the deployment.
mc admin info 'target'

# List buckets.
mc ls 'target'

# List objects in buckets.
mc ls 'target/bucket'
mc ls --recursive --versions --incomplete 'target/bucket/'

# Show a hierarchical tree view.
mc tree
mc tree --files

# Display metadata for objects or buckets.
mc stat
mc stat --recursive

# Search for objects by criteria.
mc find
```

```plaintext
GET /minio/health/live
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
- [Blog]
- [Community]
- [Ask Devin]

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
[Blog]: https://blog.min.io
[Codebase]: https://github.com/minio
[Community]: https://slack.min.io
[Documentation]: https://docs.min.io
[Website]: https://min.io

<!-- Others -->
[Ask Devin]: https://deepwiki.com/minio/minio
