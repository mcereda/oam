# ffmpeg

1. [TL;DR](#tldr)
1. [Format conversion](#format-conversion)
   1. [WebM to GIF](#webm-to-gif)
   1. [WebM to MP4](#webm-to-mp4)
1. [Sources](#sources)

## TL;DR

```sh
# Convert a webm file to GIF.
ffmpeg -y -i 'rec.webm' -vf 'palettegen' 'palette.png'
ffmpeg -y -i 'rec.webm' -i 'palette.png' -filter_complex 'paletteuse' -r 10 'out.gif'
```

## Format conversion

### WebM to GIF

```sh
ffmpeg -y -i 'rec.webm' -vf 'palettegen' 'palette.png'
ffmpeg -y -i 'rec.webm' -i 'palette.png' -filter_complex 'paletteuse' -r 10 'out.gif'
```

Here `rec.webm` is the recorded video.<br/>
The first command creates a palette out of the webm file. The second command converts the webm file to gif using the
created palette.

### WebM to MP4

```sh
ffmpeg -i 'input.webm' -c 'copy' 'output.mp4'
ffmpeg -fflags '+genpts' -r '24' -i 'input.webm' 'output.mp4'
```

## Sources

- [Convert a webm file to gif]
- [How to convert a webm video to a gif on the command line]
- [WebM to MP4 conversion using ffmpeg]

<!--
  References
  -->

<!-- Others -->
[convert a webm file to gif]: https://mundanecode.com/posts/convert-webm-to-gif
[how to convert a webm video to a gif on the command line]: https://askubuntu.com/questions/506670/how-to-do-i-convert-an-webm-video-to-a-animated-gif-on-the-command-line
[webm to mp4 conversion using ffmpeg]: https://stackoverflow.com/questions/18123376/webm-to-mp4-conversion-using-ffmpeg
