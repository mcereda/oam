# Antigen

## Table of contents <!-- omit in toc -->

1. [Troubleshooting](#troubleshooting)
   1. [While loading, a completion fails with error `No such file or directory`.](#while-loading-a-completion-fails-with-error-no-such-file-or-directory)
1. [Further readings](#further-readings)

## Troubleshooting

### While loading, a completion fails with error `No such file or directory`.

Example:

```sh
tee: /Users/user/.antigen/bundles/robbyrussell/oh-my-zsh/cache//completions/_helm: No such file or directory
/Users/user/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/helm/helm.plugin.zsh:source:9: no such file or directory: /Users/user/.antigen/bundles/robbyrussell/oh-my-zsh/cache//completions/_helm
```

The issue is due of the `$ZSH_CACHE_DIR/completions` being missing and `tee` not creating it on Mac OS X. Create the missing `completions` directory and re-run antigen:

```sh
mkdir -p $ZSH_CACHE_DIR/completions
antigen apply
```

## Further readings

- [Github]'s repository
- Antigen's [Wiki]

<!--
  References
  -->

<!-- Upstream -->
[github]: https://github.com/zsh-users/antigen
[wiki]: https://github.com/zsh-users/antigen/wiki
