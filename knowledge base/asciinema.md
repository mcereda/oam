# Asciinema

Terminal session recorder.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

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
asciinema rec -i '2' 'path/to/file.cast' -t 'title' --overwrite -c 'command'
asciinema rec --idle-time-limit '2' 'path/to/file.cast' --title 'title' --overwrite --cols '120' --command 'fish -l'


# Record sessions *and* upload them to the website.
asciinema rec

# Play local sessions.
asciinema play 'path/to/file.cast'

# Share local recordings on the website.
asciinema upload 'path/to/file.cast'
```

```sh
asciinema rec -i '2' 'demo.cast' -t 'demo' --overwrite -c 'make demo' \
&& agg --cols '160' --rows '24' --speed '1.25' --renderer 'resvg' --no-loop 'demo.cast' 'demo.gif' --theme 'solarized-dark'
```

## Further readings

- [Website]
- [Github]
- [`agg`][agg] to convert cast files into GIFs
- [VHS] as an alternative

<!--
  References
  -->

<!-- Upstream -->
[github]: https://github.com/asciinema/asciinema
[website]: https://asciinema.org/

<!-- Knowledge base -->
[agg]: agg.md
[vhs]: vhs.md
