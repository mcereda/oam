# Resize images using the CLI

Leverages `convert` from `imagemagick`.

```sh
convert input.jpg -adaptive-resize 50% output.jpg

# Scale down all images in a folder.
ls -1 | xargs -I{} convert {} -adaptive-resize 50% {}_scaled.jpg
```

Further readings

- [imagemagick]

[imagemagick]: imagemagick.md
