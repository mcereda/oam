# ImageMagick

Components:

- `compare`: diff tool
- `convert`: image conversion tool

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Scale images to 50% its original size.
magick convert -adaptive-resize '50%' 'in.jpg' 'out.jpg'

# Create GIFs from single images.
magick *.jpg 'out.gif'

# Convert N images into individual PDF documents.
magick *.jpg +adjoin 'page-%d.pdf'

# Convert N images into pages of a single PDF document.
magick *.png 'out.pdf'

# Calculate the percentage of *similarity* between 2 images.
# Avoid saving the diff.
magick compare -metric 'NCC' 'in_1.jpg' 'in_2.jpg' NULL:

# Output only the differences between 2 images.
magick compare -compose 'src' -fuzz '5%' 'in_1.jpg' 'in_2.jpg' 'diff.jpg'
```

## Further readings

- [Website]
- [image similarity comparison]

## Sources

All the references in the [further readings] section, plus the following:

- [cheat.sh/convert]
- [cheat.sh/compare]
- [Converting Multiple Images into a PDF File]
- [How to Quickly Resize, Convert & Modify Images from the Linux Terminal]
- [Diff an image using ImageMagick]
- [ImageMagick compare without generating diff image]

<!--
  References
  -->

<!-- Upstream -->
[image similarity comparison]: https://imagemagick.org/script/compare.php
[website]: https://imagemagick.org

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Others -->
[cheat.sh/compare]: https://cheat.sh/compare
[cheat.sh/convert]: https://cheat.sh/convert
[converting multiple images into a pdf file]: https://legacy.imagemagick.org/discourse-server/viewtopic.php?p=144157&sid=e7706233f81874af86ffbbf3e57b1e76#p144157
[diff an image using imagemagick]: https://stackoverflow.com/questions/5132749/diff-an-image-using-imagemagick
[how to quickly resize, convert & modify images from the linux terminal]: https://www.howtogeek.com/109369/how-to-quickly-resize-convert-modify-images-from-the-linux-terminal/
[imagemagick compare without generating diff image]: https://unix.stackexchange.com/questions/612067/imagemagick-compare-without-generating-diff-image
