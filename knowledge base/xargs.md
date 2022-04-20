# `xargs`

## TL;DR

```shell
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
```
