# PDFtk

## TL;DR

```shell
# combine multiple files
pdftk file1.pdf file2.pdf file3.pdf cat output newfile.pdf

# rotate a file
pdftk file.pdf cat 1-endleft output newfile.pdf
```

## Combine multiple files

```sh
pdftk file1.pdf file2.pdf file3.pdf cat output newfile.pdf
```

where:

- `file{1..3}.pdf` are the input file
- `cat` is the operation on the files
- `output` is the operation after the read
- `newfile.pdf` is the new file with the result

## Rotate a file

```sh
pdftk file.pdf cat 1-endleft output newfile.pdf
```

where:

- `file.pdf` is the input file
- `cat` is the operation on the file
- `1-end` is the range of pages on which execute the rotation
- `left` is the direction of the rotation
- `output` is the operation after the read
- `newfile.pdf` is the new file with the result

## Further readings

- [Combine multiple PDF files with PDFTK]
- [Lossless rotation of PDF files with ImageMagick]

[combine multiple pdf files with pdftk]: https://www.maketecheasier.com/combine-multiple-pdf-files-with-pdftk/
[lossless rotation of pdf files with imagemagick]: https://stackoverflow.com/questions/38281526/lossless-rotation-of-pdf-files-with-imagemagick/51859078#51859078
