# Whalebrew

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

Installs images like `whalebrew/wget` as `/usr/local/bin/wget`.

<details>
  <summary>Setup</summary>

Requires [Docker].

```sh
brew install 'whalebrew'
```

</details>

<details>
  <summary>Usage</summary>

Images from the [_whalebrew_ organization][whalebrew organization] are known to work correctly.<br/>
One can install any other image on Docker Hub, though they might not work as well.

> [!important]
> All `whalebrew/` images seem to be extremely dated at the time of writing.

```sh
# Search packages.
whalebrew search 'wget'

# Install packages.
whalebrew install 'whalebrew/wget'
whalebrew install 'bfirsh/ffmpeg'

# List installed packages.
whalebrew list

# Upgrade packages.
docker pull 'whalebrew/wget'

# Uninstall packages.
whalebrew uninstall 'wget'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>
</details>
-->

## Further readings

- [Codebase]
- [Homebrew]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[homebrew]: homebrew.md
[docker]: docker.md

<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/whalebrew/whalebrew

<!-- Others -->
[whalebrew organization]: https://hub.docker.com/u/whalebrew
