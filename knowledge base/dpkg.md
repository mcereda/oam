# Dpkg

## TL;DR

```sh
# add an extra architecture
dpkg --add-architecture i386

# list extra architectures
dpkg --print-foreign-architectures

# list available extra architectures
dpkg-architecture --list-known

#list all installed packages of the i386 architecture
dpkg --get-selections | grep i386 | awk '{print $1}'

# remove the i386 architecture
apt-get purge $(dpkg --get-selections | grep --color=never i386 | awk '{print $1}')
dpkg --remove-architecture i386
```

## Sources

- [How to check if dpkg-architecture --list has all the architectures?]

[how to check if dpkg-architecture --list has all the architectures?]: https://askubuntu.com/questions/852115/how-to-check-if-dpkg-architecture-list-has-all-the-architectures#852120
