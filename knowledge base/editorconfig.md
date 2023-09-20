# EditorConfig

Intro

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

File example:

```ini
# EditorConfig is awesome: https://EditorConfig.org

# top-most EditorConfig file
root = true

# Unix-style newlines with a newline ending every file
[*]
end_of_line = lf
insert_final_newline = true

# Matches multiple files with brace expansion notation
# Set default charset
[*.{js,py}]
charset = utf-8

# 4 space indentation
[*.py]
indent_style = space
indent_size = 4

# Tab indentation (no size specified)
[Makefile]
indent_style = tab

# Indentation override for all JS under lib directory
[lib/**.js]
indent_style = space
indent_size = 2

# Matches the exact files either package.json or .travis.yml
[{package.json,.travis.yml}]
indent_style = space
indent_size = 2
```

When opening a file, the compatible editor (or the EditorConfig plugin for it) looks for a file named `.editorconfig` in the directory of the opened file, **and** in every parent directory.<br/>
The search for `.editorconfig` files will stop if the root filepath is reached or an EditorConfig file with the `root=true` key pair is found.

EditorConfig files are read **top to bottom**, and the most recent rules found take precedence (last one applies).<br/>
Properties from matching EditorConfig sections are applied in the order they are read, so properties in closer files take precedence.

## Further readings

- [Website]
- [Github]

## Sources

All the references in the [further readings] section, plus the following:

- [Properties]

<!--
  References
  -->

<!-- Upstream -->
[github]: https://github.com/editorconfig/editorconfig/
[properties]: https://github.com/editorconfig/editorconfig/wiki/EditorConfig-Properties
[website]: https://editorconfig.org/

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
<!-- Files -->
<!-- Others -->
