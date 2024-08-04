# Wallabag

TODO

Intro

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
docker pull 'wallabag/wallabag'
```

</details>

<details>
  <summary>Usage</summary>

```sh
docker run -p '80:80' --name 'wallabag' -e 'SYMFONY__ENV__DOMAIN_NAME=http://localhost' 'wallabag/wallabag'
docker run -p '80:80' --name 'wallabag' -e 'SYMFONY__ENV__DOMAIN_NAME=http://localhost' \
  -v './data:/var/www/wallabag/data' -v './images:/var/www/wallabag/web/assets/images' \
  'wallabag/wallabag'

# DB upgrade migrations.
# Only required for versions that need database migrations.
docker exec -t 'wallabag' -- /var/www/wallabag/bin/console doctrine:migrations:migrate --env=prod --no-interaction
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
- [Main repository]
- [Documentation]

### Sources

- [Docker image]
- [Docker image repository]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[docker image]: https://hub.docker.com/r/wallabag/wallabag/
[docker image repository]: https://github.com/wallabag/docker
[documentation]: https://doc.wallabag.org/en/
[main repository]: https://github.com/wallabag/wallabag
[website]: https://wallabag.org/

<!-- Others -->
