# ExifTool

Platform-independent Perl library and command-line application for reading, writing and editing meta information in a
wide variety of files.<br/>
It supports many different metadata formats as well as the maker notes of many digital cameras.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Installation.
brew install 'exiftool'
sudo zypper in 'exiftool'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Show metadata in files.
exiftool 'path/to/image-1.jpg' 'path/to/image-n.jpg'

# Only show specific metadata tags.
# Tags selection is case *in*sensitive.
# Spaces in tags must be removed from the selector.
exiftool -'tagName' 'path/to/image-1.jpg'

# Add or edit metadata tags.
exiftool -author='linuxConfig' -title='Linux penguin' 'image.jpg'

# Remove metadata tags.
exiftool -author='' -title= 'image.jpg'
exiftool -all='' 'image.jpg'
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# It would be the same to use '-imageheight', '-ImageHeight' or '-imageHeight'.
exiftool -ImageHeight 'Downloads/meme.png'

# Print formatted date/time for all JPG files in the current directory.
exiftool -d "%r %a, %B %e, %Y" -DateTimeOriginal -S -s *'.jpg'

# Extract all GPS positions from an AVCHD video.
exiftool -ee -p "$gpslatitude, $gpslongitude, $gpstimestamp" 'a.m2ts'

# Recursively extract JPG images from Canon CRW files in the current directory.
# Add 'C<_JFR.jpg>' to the name of the output JPG files.
exiftool -b -JpgFromRaw -w '_JFR.jpg' -ext 'CRW' -r '.'
```

</details>

## Further readings

- [Website]
- [Github]

### Sources

- [Top 5 ways to view and edit metadata]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[github]: https://github.com/exiftool/exiftool
[website]: https://exiftool.org/

<!-- Others -->
[top 5 ways to view and edit metadata]: https://daminion.net/articles/tips/top-5-ways-to-view-and-edit-metadata/
