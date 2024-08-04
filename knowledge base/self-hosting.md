# Self-hosting

The _art_ of hosting and managing applications on one's own servers instead of consuming them from
[SaaSS][service as a software substitute] providers.

1. [Software](#software)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Software

| Name             | Description                | Alternatives                              |
| ---------------- | -------------------------- | ----------------------------------------- |
| [AWX]            | Task runner                | [CTFreak], [Rundeck], [Semaphore], [Zuul] |
| [Baikal]         | CalDAV and CardDAV server  | [Radicale]                                |
| [CTFreak]        | Task runner                | [AWX], [Rundeck], [Semaphore], [Zuul]     |
| [Gitea]          | Git server                 | [Gitlab], [Gogs]                          |
| [Gitlab]         | Git server                 | [Gitea], [Gogs]                           |
| [Gogs]           | Git server                 | [Gitea], [Gitlab]                         |
| [Home Assistant] | Home automation platform   |                                           |
| [NextCloud]      | File sharing platform      | [OwnCloud]                                |
| [OpenMediaVault] | NAS solution               | [TrueNAS]                                 |
| [Paperless-ngx]  | Document management system |                                           |
| [PhotoPrism]     | Google Photos replacement  |                                           |
| [Rundeck]        | Task runner                | [AWX], [CTFreak], [Semaphore], [Zuul]     |
| [Semaphore]      | Task runner                | [AWX], [CTFreak], [Rundeck], [Zuul]       |
| [Uptime Kuma]    | Status page                | [Gatus], [Statping-ng], [Vigil]           |
| [Zuul]           | Task runner                | [AWX], [CTFreak], [Rundeck], [Semaphore]  |
| [Wallabag]       | Web page saver             | Pocket                                    |

## Further readings

### Sources

- [awesome-selfhosted]<br/>
  List of software network services and web applications which can be hosted privately.

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[awx]: awx.md
[baikal]: baikal.md
[gitea]: gitea.md
[gitlab]: gitlab/README.md
[nextcloud]: nextcloud.md
[openmediavault]: openmediavault.md
[paperless-ngx]: paperless-ngx.md
[photoprism]: photoprism.md
[rundeck]: rundeck.md
[uptime kuma]: uptime%20kuma.md
[wallabag]: wallabag.md

<!-- Others -->
[awesome-selfhosted]: https://awesome-selfhosted.net/
[ctfreak]: https://ctfreak.com/
[gatus]: https://github.com/TwiN/gatus
[gogs]: https://github.com/gogs/gogs
[home assistant]: https://www.home-assistant.io/
[owncloud]: https://owncloud.com/
[radicale]: https://radicale.org/
[semaphore]: https://semaphoreui.com/
[service as a software substitute]: https://www.gnu.org/philosophy/who-does-that-server-really-serve.html
[statping-ng]: https://statping-ng.github.io/
[truenas]: https://www.truenas.com/
[vigil]: https://github.com/valeriansaliou/vigil
[zuul]: https://zuul-ci.org/
