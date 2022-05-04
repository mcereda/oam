# Yt-dlp

## TL;DR

> To be able to merge multiple formats into one, you will also need to install `ffmpeg`.

```shell
# Install it.
python3 -m pip install -U --user yt-dlp

# List all available formats.
yt-dlp -F AK44wAvv2E4

# Download all videos in a YouTube channel.
yt-dlp -f "bestvideo+bestaudio/best" -ciw \
  -o "%(title)s.%(ext)s" -v https://www.youtube.com/c/pbsspacetime/videos
```

## Further readings

- [GitHub]

[github]: https://github.com/yt-dlp/yt-dlp
