# Find how long a process has run in UNIX

UNIX and Linux have commands for almost everything; if there is no command, you can check some important files in the `/etc` directory or in the `/proc` virtual filesystem to find out some useful information.

## Table of contents <!-- omit in toc -->

1. [The easy way](#the-easy-way)
1. [The hackish way](#the-hackish-way)
1. [Sources](#sources)

## The easy way

If the program started today, `ps` also shows when:

```sh
$ ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
user     11610 11578  0 Aug24 ?        00:08:06 java -Djava.library.path=/usr/lib/jni:/usr/lib/alpha-linux-gnu/jni...
user     17057 25803  0 13:01 ?        00:00:24 /usr/lib/chromium-browser/chromium-browser
```

## The hackish way

Useful if the process started before today:

1. find the process ID

   ```sh
   $ ps -ef | grep java
   user 22031 22029   0   Jan 29 ? 24:53 java -Xms512M -Xmx512 Server

   $ pgrep -l java
   22031 java
   ```

1. look into the `proc` virtual filesystem for that process and check the creation date, which is when the process was started

   ```sh
   ls -ld /proc/22031
   dr-x--x--x   5 user     group           832 Jan 22 13:09 /proc/22031
   ```

## Sources

- [How to find how long a process has run in Unix]

<!--
  References
  -->

<!-- Others -->
[how to find how long a process has run in unix]: https://dzone.com/articles/how-to-find-how-long-a-process-has-run-in-unix
