# Yt-dlp

Improved fork of [youtube-dl].

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

> To be able to merge multiple formats into one, you will also need to install `ffmpeg`.

```sh
# Install it.
python3 -m pip install -U --user yt-dlp

# List all available formats.
yt-dlp -F AK44wAvv2E4

# See all available information from a video.
yt-dlp -j BaW_jenozKc

# List available subtitiles.
yt-dlp --list-subs rQnNghhPw6o

# Check what name will be used for the destination.
# Output templates at https://github.com/yt-dlp/yt-dlp#output-template, or use
# '-j' to see the json file with all of them.
yt-dlp --get-filename \
  -o "%(season_number)d.%(episode_number)02d %(episode)U.%(ext)s" \
  https://www.crunchyroll.com/some/good/serie

# Download all videos in a YouTube channel.
yt-dlp -f "bestvideo+bestaudio/best" -ciw \
  -o "%(title)#S.%(ext)s" -v https://www.youtube.com/c/pbsspacetime/videos

# As above with improvements.
# Slow down the requests to avoid issues in retrieving the data.
# Include chapters, metadata and selected subtitles.
# Prefix the file name with its timestamp, or upload date if it is null.
yt-dlp -ciw \
  --retry-sleep 3 --sleep-requests 0 --sleep-subtitles 3 \
  --embed-chapters --embed-metadata --embed-subs \
  --sub-langs "(de|en|fr|es|it|ja|nl|zh(-Han.*)?)(-en)?" \
  --sub-format "ass/srt/best" --write-auto-subs \
  -f "bestvideo+bestaudio/best" \
  -o "%(timestamp>%Y-%m-%d,upload_date>%Y-%m-%d)s  %(title)U.%(ext)s" \
  https://www.youtube.com/c/becausescience/videos
```

## Further readings

- [GitHub]
- [youtube-dl]

<!--
  References
  -->

<!-- Upstream -->
[github]: https://github.com/yt-dlp/yt-dlp

<!-- Knowledge base -->
[youtube-dl]: youtube-dl.md
