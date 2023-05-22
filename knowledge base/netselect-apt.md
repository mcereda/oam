# `netselect-apt`

Creates `sources.list` files for the fastest Debian mirrors.

It:

1. downloads the list of Debian mirrors from <http://www.debian.org/mirror/mirrors_full> using `wget`;
1. chooses the fastest servers using `netselect`;
1. tests the valid servers using `curl` if available.

The output file is written to OUTFILE.

## Table of contents <!-- omit in toc -->

1. [TL:DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL:DR

```sh
sudo netselect-apt --arch 'amd64' --country 'de' --outfile '/tmp/sources.list'
sudo netselect-apt --nonfree
sudo netselect-apt -nc 'nl'
```

## Further readings

- [`man` page][man page]

## Sources

All the references in the [further readings] section, plus the following:

- [How to find the fastest mirror in Debian and derivatives]

<!-- project's references -->
[man page]: https://manpages.debian.org/testing/netselect-apt/netselect-apt.1.en.html

<!-- internal references -->
[further readings]: #further-readings

<!-- external references -->
[how to find the fastest mirror in debian and derivatives]: https://www.unixmen.com/find-fastest-mirror-debian-derivatives/
