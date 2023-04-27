# Scan a document on Linux

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Procedure](#procedure)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Manjaro.
sudo pamac install 'sane-airscan' 'skanlite'
```

## Procedure

Install:

- the `sane-airscan` package, if the scanner is known to work in driverless mode;
- the `sane` package to use old driver-based scanning.

If the scanner is using a USB connection, make sure to also install the `ipp-usb` package and start/enable the `ipp-usb` service to allow using IPP protocol over USB connection.

Many modern scanners will immediately work over the network as long as you have `sane-airscan` installed.

SANE has lots of front ends, a non-exhaustive list of which can be found on the [sane project website][sane frontends]:

- [Simple Scan]: a simplified GUI intended to be easier to use and better integrated into the GNOME desktop than `XSane` is;
- [Skanlite]: a simple image scanning application; it does nothing more than scan and save images, and is based on the KSane backend;
- [XSane]: a full-featured GTK-based frontend; looks a bit old but provides extended functionalities.

Some OCR software are able to scan images using SANE, like gImageReader, [gscan2pdf], Linux-Intelligent-Ocr-Solution, [OCRFeeder] and [Paperwork].

## Further readings

- [SANE]
- [gscan2pdf]
- [ocrfeeder]
- [paperwork]
- [simple scan]
- [skanlite]

## Sources

All the references in the [further readings] section, plus the following:

- [SANE frontends]

<!-- sane references -->
[sane frontends]: http://www.sane-project.org/sane-frontends.html
[sane]: https://wiki.archlinux.org/title/SANE

<!-- internal references -->
[further readings]: #further-readings

<!-- external references -->
[gscan2pdf]: https://en.wikipedia.org/wiki/Scanner_Access_Now_Easy#gscan2pdf
[ocrfeeder]: https://en.wikipedia.org/wiki/OCRFeeder
[paperwork]: https://openpaper.work/
[simple scan]: https://gitlab.gnome.org/GNOME/simple-scan
[skanlite]: https://www.kde.org/applications/graphics/skanlite
