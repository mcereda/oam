# Tag

Command line tool to manipulate tags on Mac OS X files (10.9 Mavericks and above) and to query for files with those tags.<br/>
It leverages the file system's built-in metadata search functionality to quickly find all files that have been tagged with a given set of tags.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Installation.
brew install 'tag'
sudo port install 'tag'

# Add tags to files.
tag --add 'tag_name' 'path/to/file'
tag --add 'tag_name_1,…,tag with spaces N' 'file_1' … 'file_N'

# List tags for files.
tag
tag 'path/to/file'
tag --list 'path/to/file'
tag --list 'file_1' … 'file_N'
tag --recursive

# Replace *all* tags in files with new ones.
tag --set 'tag_name' 'path/to/file'
tag --set 'tag_name_1,…,tag with spaces N' 'file_1' … 'file_N'

# Remove *specific* tags from files.
tag --remove 'tag_name' 'file'
tag --remove 'tag_name_1,…,tag with spaces N' 'file_1' … 'file_N'

# Remove *all* tags from files.
# The '*' wildcard matches all tags.
# Needs escaping against shell expansion.
tag --remove '*' 'file'

# List files from the input matching *specific* tags.
tag --match 'tag_name' 'path/to/file'
tag --match 'tag_name_1,…,tag with spaces N' 'file_1' … 'file_N'

# List files from the current directory matching any combination of one or more
# tags.
tag --match '*' *
tag --match '*' --recursive '.'

# List files from the current directory with *no* tags.
tag --match '' *

# Find files with *specific* tags.
tag --find 'tag_name'
tag --find 'tag_name_1,…,tag with spaces N'

# Find files with at least one tag.
tag --find '*'

# Find files with no tags.
tag --find ''
```

## Further readings

- [Github]
- [Mac OS X]

## Sources

All the references in the [further readings] section, plus the following:

- [Tagging files from the macOS command line]

<!--
  References
  -->

<!-- Upstream -->
[github]: https://github.com/jdberry/tag

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[mac os x]: README.md

<!-- Others -->
[tagging files from the macos command line]: https://brettterpstra.com/2017/08/22/tagging-files-from-the-command-line/
