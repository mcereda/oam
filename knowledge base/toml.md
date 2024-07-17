# TOML

Tom's Obvious, Minimal Language.

Minimal configuration file format. Supposedly easy to read for its "obvious" semantics.<br/>
Designed to map unambiguously to a hash table.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Case-sensitive.<br/>
Must be a valid UTF-8 encoded Unicode document.

Hash symbols mark the rest of the line as a comment, except when they are inside strings.

```toml
# Full line comment
key1 = "value"  # EOL comment
key2 = "# string, not comment"
```

Key-value pairs are the basic building blocks of TOML.<br/>
Keys stay on the left of `=` signs, values are on the right of them.<br/>
Whitespace is ignored around keys and values.<br/>
Key, `=` and value must be on the same line.<br/>
Key-value pairs must be separated by new lines.<br/>
Keys must be unique.

```toml
# valid pairs
key1 = "value1"
     key2           =                  "value2"
key3="value2"

# invalid pairs
key4 =
key5 = "value5" key5 = "value6"
key2 = "value7"
```

Keys may be _bare_, _quoted_, or _dotted_.<br/>
Bare keys allow only ASCII characters, quoted keys allow any string and dotted keys group similar properties
together.<br/>
Whitespace around dot-separated parts is ignored.

```toml
bare_key_1   =  42
2bare-2key = true
fruit.name = "banana"
fruit. color = "yellow"
fruit . flavor = "banana"
"ʎǝʞ" = "value"
'key2' = "value"
'quoted "value"' = "value"
```

## Further readings

- [Website]
- [Main repository]

### Sources

- [TOML cheatsheet]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[main repository]: https://github.com/toml-lang/toml
[website]: https://toml.io/en/

<!-- Others -->
[toml cheatsheet]: https://quickref.me/toml.html
