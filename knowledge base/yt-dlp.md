# Yt-dlp

Improved fork of [youtube-dl].

## TL;DR

> To be able to merge multiple formats into one, you will also need to install `ffmpeg`.

```sh
# Install it.
python3 -m pip install -U --user yt-dlp

# List all available formats.
yt-dlp -F AK44wAvv2E4

# Check what name will be used for the destination.
# Output templates at https://github.com/yt-dlp/yt-dlp#output-template
yt-dlp --get-filename -o "test video.%(ext)s" BaW_jenozKc
yt-dlp --get-filename -o "%(season)s.%(episode_number)02d.%(episode)s.%(ext)s" \
  https://www.crunchyroll.com/some/good/serie

# Download all videos in a YouTube channel.
yt-dlp -f "bestvideo+bestaudio/best" -ciw \
  -o "%(title)s.%(ext)s" -v https://www.youtube.com/c/pbsspacetime/videos
```

## Further readings

- [GitHub]
- [youtube-dl]

[youtube-dl]: youtube-dl.md

[github]: https://github.com/yt-dlp/yt-dlp
