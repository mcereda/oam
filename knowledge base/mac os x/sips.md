# The Scriptable Image Processing System (SIPS)

Command-line tool shipped by default with Mac OS X which allows basic image manipulation.<br/>
Think [ImageMagick], but not as powerful.

Used to query or modify raster image files (JPG/GIF/PNG) and ColorSync ICC profiles.<br/>
Image processing options include flip, rotate, and change image format/width/height.

Its functionality can be used through the "Image Events" AppleScript suite, and supports executing JavaScript to either modify or generate images.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Retain ratio.
# Save as different file.
sips -Z '1000' -o 'resized.jpg' 'IMG_20190527_013903.jpg'
```

## Further readings

- [`man` page][man page]
- [Mac OS X]
- [ImageMagick]

<!--
  References
  -->

<!-- Knowledge base -->
[imagemagick]: ../imagemagick.md
[mac os x]: README.md

<!-- Others -->
[man page]: https://ss64.com/osx/sips.html
