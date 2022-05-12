# Envsubst

Substitutes environment variables in shell format strings.

## TL;DR

```shell
envsubst < input.file
envsubst < input.file > output.file
```

```shell
$ cat hello.file
hello $NAME

$ NAME='mek' envsubst < hello.file
hello mek
```
