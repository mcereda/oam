# Vim

## Tl;DR

```shell
# Go to a particular line.
42G
42gg
:42<CR>

# Get help on something.
:help modeline
```

## Modelines

Set different options for a particular file.

> The `modeline` option must be enabled in order to take advantage of this.  
> This option is **set** by default for Vim running in nocompatible mode, but some notable distributions of Vim disable it in the system's `vimrc` for security. In addition, the option is **off** by default when editing as `root`.

See `:help modeline` for more information.

The modeline line needs to:

- be placed near the top of the file; how near, will depend on the modeline settings
- start with a comment opening for the file type.

> The space between the comment opening and 'vim' is necessary for the modeline to be recognized.

Examples:

```text
# vim: set expandtab:

# -*- mode: ruby -*-
# vi: set ft=ruby :

/* ex: set ts=8 sw=4 tw=0 noet : */
```

## Sources

- [Modeline magic]
- [Embed vim settings in file]
- [Basic vimrc]
- [Set whitespace preferences by filetype]

[basic vimrc]: https://github.com/amix/vimrc/blob/master/vimrcs/basic.vim
[embed vim settings in file]: https://stackoverflow.com/questions/3958416/embed-vim-settings-in-file#3958516
[modeline magic]: https://vim.fandom.com/wiki/Modeline_magic
[set whitespace preferences by filetype]: https://stackoverflow.com/questions/1562633/setting-vim-whitespace-preferences-by-filetype#1563552
