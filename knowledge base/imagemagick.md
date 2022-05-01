# ImageMagick

Components:

- `convert`: image conversion tool

## TL;DR

```shell
# scale an image to 50% its original size
convert IMG_20200117_135049.jpg -adaptive-resize 50% IMG_20200117_135049_resized.jpg

# create a gif using images
magick *.jpg images.gif

# convert n images to individual pdf pages
magick *.jpg +adjoin page-%d.pdf

# convert n images to a single pdf document
magick *.png out.pdf
```

## Further readings

- [Website]
- [cheat.sh/convert]

[cheat.sh/convert]: https://cheat.sh/convert
[website]: https://imagemagick.org

## Sources

- [Converting Multiple Images into a PDF File]

[converting multiple images into a pdf file]: https://legacy.imagemagick.org/discourse-server/viewtopic.php?p=144157&sid=e7706233f81874af86ffbbf3e57b1e76#p144157
