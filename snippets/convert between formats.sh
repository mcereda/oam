#!/usr/bin/env sh

# svg to png
# https://medium.com/@instanceofMA/convert-an-svg-to-png-with-right-click-on-macos-2353d151f4eb
brew install 'librsvg'
rsvg-convert -ah '96' 'icon.svg' > 'icon-96.png'
rsvg-convert -ah '96' 'icon.svg' -o 'icon-96.png'

# webm to gif
ffmpeg -y -i 'rec.webm' -vf 'palettegen' 'palette.png'
ffmpeg -y -i 'rec.webm' -i 'palette.png' -filter_complex 'paletteuse' -r 10 'out.gif'

# webm to mp4
ffmpeg -i 'input.webm' -c 'copy' 'output.mp4'
ffmpeg -fflags '+genpts' -r '24' -i 'input.webm' 'output.mp4'

# webp to gif
magick -delay '10' -dispose 'none' 'input.webp' -coalesce -loop '0' -layers 'optimize' 'output.gif'

# webp to png
dwebp 'input.webp' -o 'output.png'
dwebp 'input.webp' -mt -o 'output.png' -resize '192' '192'
