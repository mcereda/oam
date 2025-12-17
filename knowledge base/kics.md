# Kics

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
docker pull 'checkmarx/kics'

cat <<EOF > kics.config
---
exclude-paths:
  # The container starts in '/app/bin', these paths are relative to there.
  # See the command in the lefthook configuration.
  - repository/container-images/image-builder
exclude-severities: info,low
EOF
```

</details>

<details>
  <summary>Usage</summary>

```sh
docker run -t -v "${PWD}:/workdir" 'checkmarx/kics' scan -p '/workdir'
docker run -t -v "${PWD}:/workdir" 'checkmarx/kics' \
  scan -p '/workdir' -o '/workdir/output' --report-formats "glsast,html,pdf" --output-name kics-result
```

</details>

<!-- Uncomment if needed
<details>
  <summary>Real world use cases</summary>
</details>
-->

## Further readings

- [Website]
- [Codebase]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/Checkmarx/kics/
[Website]: https://docs.kics.io/latest/

<!-- Others -->
