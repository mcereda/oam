# replicatedctl

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Get the status of the whole system.
replicatedctl system status

# Show information about the loaded license.
replicatedctl license inspect

# Load a new license.
replicatedctl license-load < 'path/to/license.rli'
replicatedctl license-load --airgap-package 'path/to/package' < 'path/to/license.rli'

# Get the detailed status of the application.
replicatedctl app status

# Start the application.
replicatedctl app start

# Stop the application.
replicatedctl app stop

# Show detailed information about the application.
replicatedctl app inspect

# Export the application's settings.
replicatedctl app-config export
replicatedctl app-config export > 'settings.json'
replicatedctl app-config export --template '{{ .enc_password.Value }}'

# Apply changes to the application's settings.
replicatedctl app apply-config
```

## Sources

- [Command reference]

<!--
  References
  -->

<!-- Upstream -->
[command reference]: https://help.replicated.com/api/replicatedctl/
