# Compare two PDF files

Install and use [`diffpdf`][diffpdf] (preferred) or [`diff-pdf`][diff-pdf]:

```sh
sudo pacman -S diffpdf
sudo zypper install diff-pdf
```

```sh
diffpdf file1 file2
```

As an alternative:

```sh
# create a pdf with the diff as red pixels
magick compare -verbose -debug coder $PDF_1 $PDF_2 -compose src /tmp/$OUT_FILE.tmp

# merge the diff-pdf with background PDF_1
pdftk /tmp/$OUT_FILE.tmp background $PDF_1 output $OUT_FILE
```

## Further readings

- [`diffpdf`][diffpdf]
- [`diff-pdf`][diff-pdf]
- [ImageMagick]
- [`pdftk`][pdftk]

## Sources

- [Compare PDF Files With DiffPDF]
- [PDF compare on linux command line]

<!--
  References
  -->

<!-- Knowledge base -->
[diffpdf]: diffpdf.md
[diff-pdf]: diff-pdf.md
[imagemagick]: imagemagick.md
[pdftk]: pdftk.md

<!-- Others -->
[compare pdf files with diffpdf]: https://www.linuxandubuntu.com/home/compare-pdf-files-with-diffpdf-in-ubuntu-linux-debian-fedora-other-derivatives
[pdf compare on linux command line]: https://stackoverflow.com/questions/6469157/pdf-compare-on-linux-command-line#7228061
