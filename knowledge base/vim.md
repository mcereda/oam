# Vim

1. [TL;DR](#tldr)
1. [Modelines](#modelines)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Go to a particular line.
42G
42gg
:42<CR>

# Delete all file's lines.
:1,$d

# Substitute text.
:s/old/new/    # 'old' to 'new', only once
:s/some/any/g  # 'some' to 'any', all occurrences from the current cursor's position
:%s/    /\t/g  # 4-spaces indentations to tabs, all occurrences in the whole file

# Enable auto indentation per file type.
:filetype plugin indent on

# Render existing tab as 4 spaces in width.
:set tabstop=4

# Insert 4 spaces of width when indenting with '>'.
:set shiftwidth=4

# Insert 4 spaces when indenting with 'tab'.
:set expandtab

# Align the file to the current indentation settings.
:retab

# Get help on something.
:help modeline
```

## Modelines

Set different options for a particular file.

> The `modeline` option must be enabled in order to take advantage of this.<br/>
> This option is **set** by default for Vim running in nocompatible mode, but some notable distributions of Vim disable
> it in the system's `vimrc` for security. In addition, the option is **off** by default when editing as `root`.

See `:help modeline` for more information.

The modeline line needs to:

- be placed near the top of the file; how near, will depend on the modeline settings
- start with a comment opening for the file type.

> The space between the comment opening and 'vim' is necessary for the modeline to be recognized.

Examples:

```txt
# vim: set expandtab:

# -*- mode: ruby -*-
# vi: set ft=ruby :

/* ex: set ts=8 sw=4 tw=0 noet : */
```

## Further readings

### Sources

- [Modeline magic]
- [Embed vim settings in file]
- [Basic vimrc]
- [Set whitespace preferences by filetype]
- [Find and Replace in Vim / Vi]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Others -->
[basic vimrc]: https://github.com/amix/vimrc/blob/master/vimrcs/basic.vim
[embed vim settings in file]: https://stackoverflow.com/questions/3958416/embed-vim-settings-in-file#3958516
[find and replace in vim / vi]: https://linuxize.com/post/vim-find-replace/
[modeline magic]: https://vim.fandom.com/wiki/Modeline_magic
[set whitespace preferences by filetype]: https://stackoverflow.com/questions/1562633/setting-vim-whitespace-preferences-by-filetype#1563552
