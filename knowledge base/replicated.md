# Replicated

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Get Replicated's logs.
docker logs replicated

# Reveal Terraform Enterprise instances' Initial Admin Creation Token.
replicated admin --tty=0 retrieve-iact
```

## Further readings

- [replicatedctl]
- [Configuration file example]

<!--
  References
  -->

<!-- Knowledge base -->
[replicatedctl]: replicatedctl.md

<!-- Files -->
[configuration file example]: ../examples/terraform/enterprise/replicated.settings.json
