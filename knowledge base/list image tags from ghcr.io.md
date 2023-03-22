# List image tags from ghcr.io

## Table of contents <!-- omit in toc -->

1. [TL:DR](#tldr)
1. [Further readings](#further-readings)

## TL:DR

Use the `tags/list` endpoint to grab all available tags:

```sh
$ curl https://ghcr.io/token\?scope\="repository:jbruchon/jdupes:pull"
{"token":"djE…MjA="}

$ curl https://ghcr.io/v2/jbruchon/jdupes/tags/list \
    -H "Authorization: Bearer djE…MjA="
{"name":"jbruchon/jdupes","tags":["latest","master","alpine","master-alpine"]}
```

## Further readings

- [How to check if a container image exists on GHCR?]

<!-- project's references -->
<!-- internal references -->

<!-- external references -->
[how to check if a container image exists on ghcr?]: https://github.com/orgs/community/discussions/26279#discussioncomment-3251171
