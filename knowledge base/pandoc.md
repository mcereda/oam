# Pandoc

Haskell library for converting from one markup format to another.<br/>
The command-line tool uses this library.

Pandoc's enhanced version of Markdown includes syntax for tables, definition lists, metadata blocks, footnotes,
citations, math, and more.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Pandoc consists of a set of readers.<br/>
Those readers parse text in a given format, and produce:

- A native representation of the document (an abstract syntax tree or AST), and
- A set of writers.

The writers convert the document's native representation into the target format.

Adding an input or output format requires only adding a reader or writer.

Users can run custom pandoc filters to modify the intermediate AST.

> Pandoc's intermediate representation of a document is less expressive than many of the formats it converts
> between.<br/>
> As such, one should **not** expect perfect conversions between every format and every other.
>
> Pandoc attempts to preserve the structural elements of a document, but not formatting details such as margin
> size.<br/>
> Some document elements (i.e., complex tables) may **not** fit into pandoc's simple document model.

If no input files are specified, input is read from `stdin`.

The output goes to `stdout` by default.

If the input or output format is not specified explicitly, pandoc will attempt to guess it from the extensions of the
filenames.<br/>
If no input file is specified or if the input files' extensions are unknown, the input format will be assumed to be
Markdown.<br/>
If no output file is specified or if the output file's extension is unknown, the output format will default to HTML.

Pandoc uses the UTF-8 character encoding for both input and output.<br/>
If one's local character encoding is **not** UTF-8, one should pipe input and output through `iconv`:

```sh
iconv -t 'utf-8' 'input.txt' | pandoc | iconv -f 'utf-8'
```

```sh
# Install.
apt install 'pandoc'
brew install 'pandoc'
dnf install 'pandoc'
yum install 'pandoc'
zypper install 'pandoc-cli'

# Print the lists of supported formats.
pandoc --list-input-formats
pandoc --list-output-formats

# Convert between formats.
# If the format is not specified, it will try to guess.
pandoc -f 'html' -t 'markdown' 'input.html'
pandoc -r 'html' -w 'markdown' 'https://www.fsf.org'
pandoc --from 'markdown' --write 'docx' 'input.md'
pandoc --read 'markdown' --to 'rtf' 'input.md'
pandoc -o 'output.tex' 'input.txt'

# By default, pandoc produces document fragments.
# Use the '-s', '--standalone' option to produce a standalone document.
pandoc -s --output 'output.pdf' 'input.html'

# If multiple input files are given at once, pandoc will concatenate them all with blank lines between them before
# parsing.
# Use `--file-scope` to parse files individually.

# Convert to PDF.
# The default way leverages LaTeX, requiring a LaTeX engine to be installed.
# Alternative engines allow 'ConTeXt', 'roff ms' or 'HTML' as intermediate formats.
pandoc … 'input.html'
pandoc … --pdf-engine 'context' 'https://www.fsf.org'
pandoc … --pdf-engine 'html' -c 'style.css' 'input.html'

# Render markdown documents and show them in `links`.
pandoc --standalone 'docs/pandoc.md' | links
```

## Further readings

- [Website]
- [Manual]

### Sources

- [Creating a PDF]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[creating a pdf]: https://pandoc.org/MANUAL.html#creating-a-pdf
[manual]: https://pandoc.org/MANUAL.html
[website]: https://pandoc.org/
