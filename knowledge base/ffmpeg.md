# ffmpeg

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Format conversion](#format-conversion)
   1. [Webm to GIF](#webm-to-gif)
1. [Sources](#sources)

## TL;DR

```sh
# Convert a webm file to GIF.
ffmpeg -y -i 'rec.webm' -vf 'palettegen' 'palette.png'
ffmpeg -y -i 'rec.webm' -i 'palette.png' -filter_complex 'paletteuse' -r 10 'out.gif'
```

## Format conversion

### Webm to GIF

```sh
ffmpeg -y -i 'rec.webm' -vf 'palettegen' 'palette.png'
ffmpeg -y -i 'rec.webm' -i 'palette.png' -filter_complex 'paletteuse' -r 10 'out.gif'
```

Here `rec.webm` is the recorded video.  
The first command creates a palette out of the webm file. The second command converts the webm file to gif using the created palette.

## Sources

- [Convert a webm file to gif]
- [How to convert a webm video to a gif on the command line]

<!--
  References
  -->

<!-- Others -->
[convert a webm file to gif]: https://mundanecode.com/posts/convert-webm-to-gif
[how to convert a webm video to a gif on the command line]: https://askubuntu.com/questions/506670/how-to-do-i-convert-an-webm-video-to-a-animated-gif-on-the-command-line
