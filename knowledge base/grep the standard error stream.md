# Grep the standard error stream

If you're using `bash` or `zsh` you can employ anonymous pipes:

```sh
ffmpeg -i 01-Daemon.mp3 2> >(grep -i Duration)
```

If you want the filtered redirected output on `stderr` again, add the `>&2` redirection to grep:

```sh
command 2> >(grep something >&2)
```

`2>` redirects `stderr` to a pipe, while `>(command)` reads from it. This is _syntactic sugar_ to create a pipe (not a file) and remove it when the process completes. They are effectively anonymous, because they are not given a name in the filesystem.  
Bash calls this _process substitution_:

> Process substitution can also be used to capture output that would normally go to a file, and redirect it to the input of a process.

You can exclude `stdout` and grep `stderr` redirecting it to `null`:

```sh
command 1>/dev/null 2> >(grep -oP "(.*)(?=pattern)")
```

> Do note that **the target command of process substitution runs asynchronously**.  
> As a consequence, `stderr` lines that get through the grep filter may not appear at the place you would expect in the rest of the output, but even on your next command prompt.

## Further readings

- Knowledge base on [grep]

[grep]: grep.md

## Sources

- Answer on [StackExchange] about [how to grep the standard error stream]

[stackexchange]: https://unix.stackexchange.com

[how to grep the standard error stream]: https://unix.stackexchange.com/questions/3514/how-to-grep-standard-error-stream-stderr/#3657
