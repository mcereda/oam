# Baïkal

1. [TL;DR](#tldr)
1. [Troubleshooting](#troubleshooting)
   1. [`Error: Class 'DOMDocument' not found in /mnt/are/www/dav/vendor/sabre/dav/lib/DAV/Server.php:256`](#error-class-domdocument-not-found-in-mntarewwwdavvendorsabredavlibdavserverphp256)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
docker pull 'ckulka/baikal-docker'
```

Connect to the server via HTTP(S) after first run for first configuration if none was provided.

</details>

<details>
  <summary>Usage</summary>

```sh
docker run --rm -p '80:80' 'ckulka/baikal:nginx'
```

</details>

## Troubleshooting

### `Error: Class 'DOMDocument' not found in /mnt/are/www/dav/vendor/sabre/dav/lib/DAV/Server.php:256`

Refer [Baikal PHP Error], then [Baïkal dependencies].

Ensure the following are available:

- PHP's XML module (`php-xml` in [APT]).
- PHP's MBSTRING module (`php-mbstring` in [APT]).

## Further readings

- [Website]
- [Codebase]
- [Self-hosting]

### Sources

- [ckulka/baikal-docker]
- [Baikal PHP Error]
- [Baïkal dependencies]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[apt]: apt.md
[self-hosting]: self-hosting.md

<!-- Files -->
<!-- Upstream -->
[baïkal dependencies]: https://github.com/sabre-io/Baikal/wiki/Ba%C3%AFkal-dependencies
[baikal php error]: https://github.com/sabre-io/Baikal/issues/701
[Codebase]: https://github.com/sabre-io/Baikal
[Website]: https://sabre.io/baikal/

<!-- Others -->
[ckulka/baikal-docker]: https://github.com/ckulka/baikal-docker
