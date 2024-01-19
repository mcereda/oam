# Securely delete files

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

FIXME: add disk encryption considerations.

On systems with GNU userland:

1. Pass files with [`shred`][gnu shred].

On Mac OS X:

1. Enable trim enforcement if it is using a SSD:

   ```sh
   sudo trimforce enable
   ```

## Further readings

- [GNU `shred`][gnu shred]

## Sources

All the references in the [further readings] section, plus the following:

- [Mac OS X]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[gnu shred]: gnu%20userland/shred.md
[mac os x]: mac%20os%20x/README.md
