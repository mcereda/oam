# Youtube-DL

## TL;DR

```shell
# limit the bandwidth
youtube-dl --format 313 --limit-rate 2M $URL

# list all available formats
youtube-dl --list-formats ${URL}

# download bestvideo and bestaudio formats and merge them in a single file
youtube-dl -f bestvideo+bestaudio $URL

# download formats separately and do not merge them
youtube-dl -f bestvideo,bestaudio $URL

# download the best all-around formats
youtube-dl -f best $URL

# also download thumbnails and other info (in separate files)
youtube-dl --write-description --write-info-json --write-annotations --write-sub --write-thumbnail $URL

# sequentially download a list of videos
parallel --jobs 1 --retries 10 'youtube-dl -f bestvideo+bestaudio "https://www.youtube.com/watch?v={}"' ::: ${CODES[@]}
```

## Installation

The preferred method is to just download it from the [project]:

```shell
curl --location https://yt-dl.org/downloads/latest/youtube-dl --remote-name
chown a+x youtube-dl
python3 youtube-dl …
```

Alternatively, most package managers will have the package available.

## Further readings

- Github [project]'s page
- [Website]
- [Youtube-DL tutorial with examples for beginners]

[project]: https://github.com/ytdl-org/youtube-dl
[website]: http://ytdl-org.gitlab.io/youtube-dl

[youtube-dl tutorial with examples for beginners]: https://ostechnix.com/youtube-dl-tutorial-with-examples-for-beginners
