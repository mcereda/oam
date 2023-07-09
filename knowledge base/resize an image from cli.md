# Resize images using the CLI

Leverage `convert` from `imagemagick`:

```sh
magick convert -adaptive-resize '50%' 'in.jpg' 'out.jpg'

# Scale down all images in a folder.
ls -1 | xargs -I{} magick convert -adaptive-resize '50%' {} {}_scaled.jpg
```

## Further readings

- [imagemagick]

<!--
  References
  -->

<!-- Others -->
[imagemagick]: imagemagick.md
