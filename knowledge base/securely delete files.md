# Securely delete files

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

FIXME: add disk encryption considerations.

On systems with GNU userland:

1. Pass files with [`shred`][gnu shred].

On macOS:

1. Enable trim enforcement if it is using a SSD:

   ```sh
   sudo trimforce enable
   ```

## Further readings

- [GNU `shred`][gnu shred]

## Sources

All the references in the [further readings] section, plus the following:

- [macOS]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[GNU shred]: gnu%20userland/shred.md
[macOS]: macos/README.md
