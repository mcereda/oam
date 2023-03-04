# Envsubst

Substitutes environment variables in shell format strings.

## TL;DR

```sh
envsubst < input.file
envsubst < input.file > output.file
```

```sh
$ cat hello.file
hello $NAME

$ NAME='Johnny' envsubst < hello.file
hello Johnny
```
