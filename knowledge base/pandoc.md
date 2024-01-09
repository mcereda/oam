# Pandoc

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Install.
apt install 'pandoc'
brew install 'pandoc'
dnf install 'pandoc'
yum install 'pandoc'
zypper install 'pandoc-cli'

# Convert between formats.
# If the format is not specified, it will try to guess.
pandoc -f 'html' -t 'markdown' 'input.html'
pandoc -r 'html' -w 'markdown' 'https://www.fsf.org'
pandoc --from 'markdown' --write 'docx' 'input.md'
pandoc --read 'markdown' --to 'rtf' 'input.md'
pandoc -o 'output.tex' 'input.txt'
pandoc -s --output 'output.pdf' 'input.html'

# Convert to PDF.
# The default way leverages LaTeX, requiring a LaTeX engine to be installed.
# Alternative engines allow ConTeXt, roff ms or HTML as intermediate formats.
pandoc … 'input.html'
pandoc … --pdf-engine 'context' 'https://www.fsf.org'
pandoc … --pdf-engine 'html' -c 'style.css' 'input.html'
```

## Further readings

- [Website]

## Sources

All the references in the [further readings] section, plus the following:

- [Creating a PDF]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Upstream -->
[creating a pdf]: https://pandoc.org/MANUAL.html#creating-a-pdf
[website]: https://pandoc.org/
