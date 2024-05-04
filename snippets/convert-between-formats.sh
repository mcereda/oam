#!/usr/bin/env sh

# svg to png
rsvg-convert -ah '96' 'icon.svg' -o 'icon-96.png'

# webm to gif
ffmpeg -y -i 'rec.webm' -vf 'palettegen' 'palette.png'
ffmpeg -y -i 'rec.webm' -i 'palette.png' -filter_complex 'paletteuse' -r 10 'out.gif'

# webm to mp4
ffmpeg -i 'input.webm' -c 'copy' 'output.mp4'
ffmpeg -fflags '+genpts' -r '24' -i 'input.webm' 'output.mp4'
