# Jellyfin

Free software media system.<br/>
Allows streaming to any device from one's own server, with no strings attached.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

_Libraries_ are virtual collections of media.<br/>
They can contain files from several different locations on the server.

One will see a page to add libraries when they first create the server.<br/>
Libraries can be then added, modified, or removed at any time from the settings.

<details style='padding: 0 0 1rem 1rem'>

1. Log in to Jellyfin's web interface in the web browser.
1. On the user menu in the top right corner, select _Dashboard_.
1. On the left side menu, in the _Server_ section, select _Libraries_ > _Libraries_.
1. Take action:
   - Click _Add Media Library_ to add a new library.
   - Click the hamburger menu of the library to modify, then select _Manage library_ to make changes to it.
   - Click the hamburger menu of the library to delete, then select _Remove_ to delete it.

</details>

A single library can encompass multiple paths.<br/>
Exclude a folder and its children from scans by creating **empty** `.ignore` files within those directories.<br/>
Exclude only specific files and folders from scans by **listing** them in the `.ignore` file within their directory. Use
the same format as git's `.gitignore` files. This feature is available since version 10.11.

The three most common types of content are _movies_, _shows_, and _music_.<br/>
These have the best support in client apps. One can also add other types of media, such as books or photos.<br/>
When having different types of media in a single folder, one can also label it as _mixed_. In this case, it will be a
generic folder view that displays all files in that library. Use of this type is currently discouraged.

Jellyfin **suggests** organizing and naming files in specific ways depending on their content type.<br/>
Doing so automates the recognition process, but allows to manually identify the media later.

<details style='padding: 0 0 0 1rem'>
  <summary>Movies</summary>

Refer [Media / Movies][documentation / media / movies].

Movies should be organized into individual folders for each movie. The folder can optionally contain extra files.<br/>
The folder containing the movie should be named in the format `Name (optional year) [optional metadata provider id]`.

```plaintext
Movies
├── The Illusionist (2006)
│   ├── The Illusionist (2006).mp4
│   ├── The Illusionist (2006).nfo
│   ├── The Illusionist (2006).en_us.srt
│   ├── cover.png
│   └── theme.mp3
├── …
└── Your Name. (2016) [imdbid-tt5311514]
    ├── backdrop.jpg
    └── VIDEO_TS
        ├── VIDEO_TS.BUP
        ├── VIDEO_TS.IFO
        ├── VIDEO_TS.VOB
        ├── VTS_01_0.BUP
        ├── VTS_01_0.IFO
        ├── VTS_01_0.VOB
        ├── VTS_01_1.VOB
        └── VTS_01_2.VOB
```

</details>
<details style='padding: 0 0 1rem 1rem'>
  <summary>Shows</summary>

Refer [Media / Shows][documentation / media / shows].

Shows should be organized into series folders, then into season folders under each series.<br/>
The folder containing the show should be named in the format `Name (optional year) [optional metadata provider id]`.

```plaintext
Shows
├── Konosuba (2016)
│   ├── Season 1
│   │   ├── Konosuba (2016) S01E01 This Self-Proclaimed Goddess and Reincarnation in Another World!.avi
│   │   ├── Konosuba (2016) S01E01 This Self-Proclaimed Goddess and Reincarnation in Another World!.nfo
│   │   ├── Konosuba (2016) S01E01 This Self-Proclaimed Goddess and Reincarnation in Another World!.en_us.srt
│   │   ├── …
│   │   └── Konosuba (2016) S01E10 Final Flame for this Over-the-top Fortress!.en_us.srt
│   └── Season 2
│       ├── Konosuba S02E01 …
│       └── …
├── …
```

</details>

<!-- Uncomment if used
<details>
  <summary>Setup</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Website]
- [Codebase]
- [Blog]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[Blog]: https://jellyfin.org/posts
[Codebase]: https://github.com/jellyfin/jellyfin
[Documentation / Media / Movies]: https://jellyfin.org/docs/general/server/media/movies
[Documentation / Media / Shows]: https://jellyfin.org/docs/general/server/media/shows
[Documentation]: https://jellyfin.org/docs
[Website]: https://jellyfin.org/

<!-- Others -->
