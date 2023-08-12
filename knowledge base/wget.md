# `wget`

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Download all the pictures from a webpage.
# Limit yourself to JPG files from the domain storing them.
# Save them in a single directory.
wget 'https://www.theskyfolk.com/photo' -Hcr -D'images.squarespace-cdn.com' \
  --e'robots=off' -t'3' -w'1' -A'jpg' -nc -nd -np --xattr
wget 'https://www.theskyfolk.com/photo' \
  --span-hosts --continue --recursive \
  --domains 'images.squarespace-cdn.com' --execute 'robots=off' \
  --tries '3' --wait '1' \
  --accept 'jpg' --no-clobber --no-directories --no-parent --xattr
```

## Further readings

- [Manual]

## Sources

All the references in the [further readings] section, plus the following:

- [Ský Fólk]

<!--
  References
  -->

<!-- Upstream -->
[manual]: https://www.gnu.org/software/wget/manual/wget.html

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Others -->
[ský fólk]: https://www.theskyfolk.com
