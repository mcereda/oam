# Asciinema

Terminal session recorder.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Installation.
sudo apt-get install asciinema
brew install 'asciinema'
sudo dnf install 'asciinema'
sudo pacman -S 'asciinema'
python3 -m 'pip' install --user 'asciinema'

# Record sessions locally.
asciinema rec 'path/to/file.cast'
asciinema rec -i 2 'path/to/file.cast' --overwrite

# Record sessions and upload them to the website.
asciinema rec

# Play local sessions.
asciinema play 'path/to/file.cast'

# Share local recordings on the website.
asciinema upload 'path/to/file.cast'
```

## Further readings

- [Website]
- [Github]
- [`agg`][agg] to convert cast files into GIFs

## Sources

All the references in the [further readings] section, plus the following:

<!--
  references
  -->

<!-- project -->
[github]: https://github.com/asciinema/asciinema
[website]: https://asciinema.org/

<!-- article sections -->
[further readings]: #further-readings

<!-- knowledge base -->
[agg]: agg.md

<!-- others -->
