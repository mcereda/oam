# Katana

> FIXME

Intro

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
brew install 'katana'
docker pull 'projectdiscovery/katana'
```

</details>

<details>
  <summary>Usage</summary>

```sh
katana -u 'http://localhost:3000'
katana -u 'https://ip-172-31-0-1.eu-west-1.compute.internal' -jc -jsl -d '10' -mr '/api/v1/' -fr '/_next/'
docker run 'projectdiscovery/katana' -u 'http://localhost:8080' -f 'qpath'
docker run 'projectdiscovery/katana:latest' -u 'http://localhost:8080,https://localhost:8443' -system-chrome -headless
```

</details>

## Further readings

- [Codebase]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[codebase]: https://github.com/projectdiscovery/katana
