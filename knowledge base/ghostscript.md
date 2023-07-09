# Ghostscript

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Reduce the size of PDF files](#reduce-the-size-of-pdf-files)
1. [Sources](#sources)

## TL;DR

```sh
# Install.
brew install ghostscript
sudo port install ghostscript

# Reduce the size of PDF files.
gs -dNOPAUSE -dQUIET -dBATCH \
  -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -dCompatibilityLevel=1.4 \
  -sOutputFile=path/to/small/file.pdf \
  path/to/massive/file.pdf
```

## Reduce the size of PDF files

Execute the following:

```sh
gs -dNOPAUSE -dQUIET -dBATCH \
  -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -dCompatibilityLevel=1.4 \
  -sOutputFile=path/to/small/file.pdf \
  path/to/massive/file.pdf
```

Use one of the following options for the value of `-dPDFSETTINGS`:

| Value       | Description                                    |
| ----------- | ---------------------------------------------- |
| `/screen`   | Screen-view-only quality, 72 dpi images        |
| `/ebook`    | Low quality, 150 dpi images                    |
| `/printer`  | High quality, 300 dpi images                   |
| `/prepress` | High quality, color preserving, 300 dpi images |
| `/default`  | Almost identical to `/screen`                  |

## Sources

- [Reducing PDF File size]

<!--
  References
  -->

<!-- Others -->
[reducing pdf file size]: https://superuser.com/questions/293856/reducing-pdf-file-size#1217306
