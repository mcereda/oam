# PhotoPrism

Photos app for the decentralized web.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Installation and configuration</summary>

  <details style="margin: 1em 0 0 1em">
    <summary>Docker compose (preferred)</summary>

[File example][docker-compose.yml]

```sh
wget 'https://dl.photoprism.app/docker/docker-compose.yml'
docker compose up -d
```

The installation example includes a pre-configured MariaDB database server.<br/>
SQLite database files will be created in the storage folder, should one remove it and provide no other database server
credentials.

| Volume                  | Description                                                                                                                                                                                                                                                                                                                                               |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/photoprism/originals` | Contains one's original photo and video files                                                                                                                                                                                                                                                                                                             |
| `/photoprism/storage`   | Configuration, cache, thumbnail, and sidecar files.<br/>It **must** always be specified to avoid losing such files after restarts or upgrades.<br/>Never configure the storage folder to be inside the originals folder, unless the name starts with a `.` to indicate that it is hidden.                                                                 |
| `/photoprism/import`    | Optional folder from which files can be transferred to the `originals` folder in a structured way that avoids duplicates.<br/>Imported files receive a canonical filename and will be organized by year and month.<br/>Never configure the import folder to be inside the originals folder, as this will cause a loop by importing already indexed files. |

  </details>
</details>

## Further readings

- [Self-hosting]
- [Website]
- [Github]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[self-hosting]: self-hosting.md

<!-- Files -->
[docker-compose.yml]: /containers/photoprism/docker-compose.original.yml

<!-- Upstream -->
[documentation]: https://docs.photoprism.app/
[github]: https://github.com/photoprism/photoprism
[website]: https://www.photoprism.app/
