# `xargs`

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Usage</summary>

```sh
# print the command to be executed and immediately start it
echo 1 2 3 4 | xargs -t mkdir

# print the command to be executed and ask for confirmation before starting it
echo 1 2 3 4 | xargs -p rm -rf

# spawn 5 clamscan processes at a time
# each process being given 1 argument from the list in input
find ~ -type f -printf "'%p' " | xargs -P 5 -n 1 clamscan

# replace a given string with arguments read from input
# useful to insert the arguments in the middle of the command to execute
find ~ -type d -name ".git" -exec dirname {} + | xargs -I // git -C "//" pull

# Use aliases as commands.
# The 'BASH_ALIASES' array works only in BASH.
# The 'aliases' array works only in ZSH.
echo 1 2 3 4 | xargs "${BASH_ALIASES[my-alias]}"
echo 1 2 3 4 | xargs $aliases['my-alias']

# Execute interactive commands.
# Reopen the TTY with '-o', '--open-tty'.
grep -lz PATTERN * | xargs -0o vi
find '.' -type 'f' -name 'Pulumi.yaml' -not -path "*/node_modules/*" -exec dirname {} '+' | xargs -otI%% pulumi up -C %%
```

</details>

## Further readings

- [An Opinionated Guide to xargs]

### Sources

- [xargs: exec command with prompt]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[an opinionated guide to xargs]: https://www.oilshell.org/blog/2021/08/xargs.html
[xargs: exec command with prompt]: https://stackoverflow.com/questions/30044927/xargs-exec-command-with-prompt#69590861
