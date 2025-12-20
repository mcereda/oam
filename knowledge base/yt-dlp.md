# Yt-dlp

Improved fork of [`youtube-dl`][youtube-dl].

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

> [!tip]
> Also install [`ffmpeg`][ffmpeg] to support merging multiple formats into one.

<details>
  <summary>Setup</summary>

```sh
brew install 'yt-dlp'
pipx install 'yt-dlp'
python3 -m pip install -U --user 'yt-dlp'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# List all available formats.
yt-dlp -F 'AK44wAvv2E4'
yt-dlp --list-formats 'AK44wAvv2E4'

# See all available information from a video.
yt-dlp -j 'BaW_jenozKc'
yt-dlp --dump-json 'BaW_jenozKc'

# List available subtitiles.
yt-dlp --list-subs 'rQnNghhPw6o'

# Check what name will be used for the destination.
# Output templates at https://github.com/yt-dlp/yt-dlp#output-template, or use
# '-j' to see the json file with all of them.
yt-dlp --get-filename \
  -o '%(season_number)d.%(episode_number)02d %(episode)U.%(ext)s' \
  'https://www.crunchyroll.com/some/good/serie'

# Get a video in the best available quality.
yt-dlp -f 'bestvideo+bestaudio/best' 'https://www.youtube.com/watch?v=abc4EFG89jK'
yt-dlp --format 'bestvideo+bestaudio/best' 'https://www.youtube.com/watch?v=abc4EFG89jK'

# Download all videos in a YouTube channel.
yt-dlp -ciw 'https://www.youtube.com/c/somechannel/videos'
yt-dlp --continue --ignore-errors --no-overwrites 'https://www.youtube.com/c/somechannel/videos'
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Get a video in the best available quality.
yt-dlp -f 'bestvideo+bestaudio/best' -ciw -o '%(title)#S.%(ext)s' 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'

# Download all videos in a YouTube channel (improved).
# Slow down the requests to avoid issues in retrieving the data.
# Include chapters, metadata and selected subtitles.
# Prefix the file name with its timestamp, or upload date if it is null.
yt-dlp -ciw \
  --retry-sleep 3 --sleep-requests 0 --sleep-subtitles 3 \
  --embed-chapters --embed-metadata --embed-subs \
  --sub-langs '(de|en|fr|es|it|ja|nl|zh(-Han.*)?)(-en)?' \
  --sub-format 'ass/srt/best' --write-auto-subs \
  -f 'bestvideo+bestaudio/best' \
  -o '%(timestamp>%Y-%m-%d,upload_date>%Y-%m-%d)s  %(title)U.%(ext)s' \
  'https://www.youtube.com/c/becausescience/videos'
```

</details>

## Further readings

- [Codebase]
- [`youtube-dl`][youtube-dl]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[ffmpeg]: ffmpeg.md
[youtube-dl]: youtube-dl.md

<!-- Upstream -->
[Codebase]: https://github.com/yt-dlp/yt-dlp
