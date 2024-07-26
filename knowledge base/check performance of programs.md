# Check performance of programs

1. [GNU time](#gnu-time)
1. [Valgrind](#valgrind)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## GNU time

```sh
# On Mac OS X.
brew install 'gnu-time'
gtime -v pulumi preview
```

## Valgrind

```sh
valgrind --tool='massif' pulumi preview
ms_print 'massif.out.12345'
```

## Further readings

- [Valgrind]

### Sources

- [How can I measure the actual memory usage of an application or process?]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[valgrind]: valgrind.md

<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[how can i measure the actual memory usage of an application or process?]: https://stackoverflow.com/questions/131303/how-can-i-measure-the-actual-memory-usage-of-an-application-or-process
