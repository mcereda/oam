# Youtube-DL

## TL;DR

```shell
# Limit the bandwidth.
youtube-dl --format 313 --limit-rate 2M video-url

# List all available formats.
youtube-dl --list-formats video-url

# Download the 'bestvideo' and 'bestaudio' formats and merge them in a single
# file.
youtube-dl -f bestvideo+bestaudio video-url

# Download formats separately and do not merge them.
youtube-dl -f bestvideo,bestaudio video-url

# Download the best all-around formats.
youtube-dl -f best video-url

# Download the first format in a list.
youtube-dl -f bestvideo+bestaudio/best video-url

# Filter formats by conditions.
youtube-dl -f bestvideo+bestaudio[height>=720]/best[filesize>100M] video-url

# Also download thumbnails and other info (in separate files).
youtube-dl --write-description --write-info-json --write-annotations \
  --write-sub --write-thumbnail video-url

# Show what name would the resulting file have
youtube-dl --get-filename -o '%(title)s.%(ext)s' video-url
youtube-dl --get-filename -o '%(title)s.%(ext)s' video-url --restrict-filenames

# Sequentially download a list of videos.
parallel --jobs 1 --retries 10 \
  'youtube-dl -f bestvideo+bestaudio "https://www.youtube.com/watch?v={}"' \
  ::: ${CODES[@]}

# Download all videos in a YouTube channel.
youtube-dl -f "bestvideo+bestaudio/best" -ciw \
  -o "%(title)s.%(ext)s" -v channel-url

# Download YouTube playlist videos in a separate directory.
# Index by video order in the playlist.
youtube-dl -o '%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s' playlist-url

# Download an entire series season.
# Keep each series and each season in separate directories.
$ youtube-dl -o "C:/MyVideos/%(series)s/%(season_number)s - %(season)s/%(episode_number)s - %(episode)s.%(ext)s" https://videomore.ru/kino_v_detalayah/5_sezon/367617
```

## Installation

The preferred method is to just download it from the [project]:

```shell
curl --location https://yt-dl.org/downloads/latest/youtube-dl --remote-name
chown a+x youtube-dl
python3 youtube-dl …
```

Alternatively, most package managers will have the package available.

> To be able to merge multiple formats into one, you will also need to install `ffmpeg` or `avconv`.

## Further readings

- Github [project]'s page
- [Website]
- [Youtube-DL tutorial with examples for beginners]
- [using youtube-dl to download entire youtube channel]

[project]: https://github.com/ytdl-org/youtube-dl
[website]: http://ytdl-org.gitlab.io/youtube-dl

[youtube-dl tutorial with examples for beginners]: https://ostechnix.com/youtube-dl-tutorial-with-examples-for-beginners
[using youtube-dl to download entire youtube channel]: https://askubuntu.com/questions/856911/using-youtube-dl-to-download-entire-youtube-channel#1245829
