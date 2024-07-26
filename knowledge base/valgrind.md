# Valgrind

TODO

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Install from source.
git clone 'https://sourceware.org/git/valgrind.git'
cd 'valgrind'
./autogen.sh
./configure
make
make install

# Install using packages.
sudo zypper install 'valgrind'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Measure how much heap memory a program uses.
valgrind --tool='massif' pulumi preview

# Get summary statistics from dump taken with massif.
ms_print 'massif.out.12345'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Website]
- [Main repository]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[main repository]: https://sourceware.org/git/valgrind.git
[website]: https://valgrind.org/

<!-- Others -->
