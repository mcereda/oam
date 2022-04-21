# TimeMachine

## TL;DR

```shell
# follow logs
log stream --style syslog --predicate 'senderImagePath contains[cd] "TimeMachine"' --info --debug

# add or set a destination
sudo tmutil setdestination
```

## Follow logs

- use `stream` to keep watching "tail style"
- use `--predicate` to filter out relevant logs
- add `--style syslog` to watch them in a syslog style
