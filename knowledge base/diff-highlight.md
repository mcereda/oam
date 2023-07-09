# `diff-highlight`

Pretty diff highlighter with emphasis on changed words.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

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

<!--
  References
  -->

<!-- Upstream -->
[github]: https://github.com/tk0miya/diff-highlight
[pypi]: https://pypi.org/project/diff-highlight/

<!-- Knowledge base -->
[git]: git.md
