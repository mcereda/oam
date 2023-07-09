# `diff-highlight`

Pretty diff highlighter with emphasis on changed words.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Installation.
pip install 'diff-highlight'
```

In `${HOME}/.gitconfig`:

```ini
# Set as default.
[core]
    pager = diff-highlight | less

# Apply to individual commands.
[pager]
    log = diff-highlight | less
    show = diff-highlight | less
    diff = diff-highlight | less
```

## Further readings

- [Github]
- [PyPi] page
- [Git]

## Sources

All the references in the [further readings] section, plus the following:

<!-- upstream -->
[github]: https://github.com/tk0miya/diff-highlight
[pypi]: https://pypi.org/project/diff-highlight/

<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
[git]: git.md

<!-- external references -->
