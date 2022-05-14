# Compare two PDF files

Install and use `diffpdf` (preferred) or `diff-pdf`:

```sh
sudo zypper install diff-pdf
```

As an alternative:

```sh
# create a pdf with the diff as red pixels
compare -verbose -debug coder $PDF_1 $PDF_2 -compose src /tmp/$OUT_FILE.tmp

# merge the diff-pdf with background PDF_1
pdftk /tmp/$OUT_FILE.tmp background $PDF_1 output $OUT_FILE
```

## Sources

- [Compare PDF Files With DiffPDF]
- [PDF compare on linux command line]

[compare pdf files with diffpdf]: https://www.linuxandubuntu.com/home/compare-pdf-files-with-diffpdf-in-ubuntu-linux-debian-fedora-other-derivatives
[pdf compare on linux command line]: https://stackoverflow.com/questions/6469157/pdf-compare-on-linux-command-line#7228061
