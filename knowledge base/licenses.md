# Licenses

1. [TL;DR](#tldr)
1. [Apache](#apache)
1. [Creative Commons](#creative-commons)
   1. [Relicensing](#relicensing)
   1. [CC vs software licenses](#cc-vs-software-licenses)
1. [MIT](#mit)
1. [Open Database License](#open-database-license)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

| License  | Best for        | Examples                                   |
| -------- | --------------- | ------------------------------------------ |
| [Apache] | Software        | Kubernetes, Terraform, Android (AOSP)      |
| [CC]     | Content         | Wikipedia, OpenStax, Arduino documentation |
| [MIT]    | Software        | React, Node.js, jQuery, Rails, .NET        |
| [ODbL]   | Structured data | OpenStreetMap, Open Food Facts             |

## Apache

Permissive license.

Similar to [MIT], but with the **explicit patent grant** forcing contributors to automatically license their patents to
users.

Includes a **patent retaliation clause** stating that the moment one sues over patents in the software their license
terminates automatically.

Version 2.0 (2004) is the current one.

| Feature            | Apache 2.0          | MIT                   |
| ------------------ | ------------------- | --------------------- |
| Patent grant       | Yes (explicit)      | No (implicit at best) |
| Patent retaliation | Yes                 | No                    |
| License notice     | Required            | Required              |
| NOTICE file        | Required if present | No                    |
| Commercial use     | Allowed             | Allowed               |

Apache 2.0 is _compatible_ with GPLv3, but **not** with GPLv2.

## Creative Commons

Purpose-built for creative works (documentation, articles, datasets, images).

Version 4.0 (2013) works globally **without** the need of jurisdiction-specific ports.

The **BY** (attribution) clause is the base. The following optional modifiers that can be added to it:

| Modifier           | Effect                                                                            |
| ------------------ | --------------------------------------------------------------------------------- |
| SA (ShareAlike)    | Derivatives must use the same license                                             |
| NC (NonCommercial) | No commercial use allowed; the copyright holder is not bound by their own license |
| ND                 | No derivatives; content can only be shared verbatim                               |

which gives the following combinations:

| License     | Commercial use | Derivatives | Same license | Examples                                                    |
| ----------- | -------------- | ----------- | ------------ | ----------------------------------------------------------- |
| CC BY       | Allowed        | Allowed     | No           | OpenStax, Flickr                                            |
| CC BY-SA    | Allowed        | Allowed     | Yes          | Wikipedia, Arduino documentation, OpenStreetMap before ODbL |
| CC BY-NC    | No             | Allowed     | No           | Some academic courseware                                    |
| CC BY-NC-SA | No             | Allowed     | Yes          | Khan Academy (some content)                                 |
| CC BY-ND    | Allowed        | No          | N/A          | Some press releases, white papers                           |
| CC BY-NC-ND | No             | No          | N/A          | Some research papers                                        |

Content in the public domain can use **CC0** to set no conditions at all.

### Relicensing

The copyright holder is never bound by their own license grant. A sole author can relicense at any time.<br/>
Multi-contributor projects require **every** contributor's consent to relicense. Some projects use Contributor
License Agreements (CLAs) to retain relicensing flexibility for this reason.

Copies obtained under the old license keep their original terms, but new copies follow the new license.

### CC vs software licenses

Software licenses (MIT, GPL, Apache) govern source code _distribution_, and deal with concepts like linking, compiling,
and sublicensing. CC licenses are designed for creative works and define rights in terms of _adaptation_, _attribution_,
and _sharing_.

Using a software license on content (or vice versa) creates legal ambiguity; CC themselves [recommend **against** using
CC for software][CC FAQ / Can I apply a Creative Commons license to software?].

## MIT

The most permissive common license.

Allows **anything** (use, modify, distribute, sell, sublicense) as long as the original copyright notice and license
text are included in the copy.

No patent grant, no copyleft, no share-alike. A single paragraph of legal text.

Has the lowest friction for users, but grants **no** protection against someone taking the work and closing the
source.<br/>
Good for software where community adoption matters more than controlling derivatives.

## Open Database License

Copyleft license specifically for **structured data** (databases, datasets, APIs backed by data).<br/>
Maintained by the Open Knowledge Foundation.

ODbL treats the _database_ (the structured collection) separately from the _contents_ (individual entries).<br/>
The copyleft applies to the **database** as a whole. Individual **facts** remain free to use.

| Requirement         | Detail                                                      |
| ------------------- | ----------------------------------------------------------- |
| Attribution         | Required                                                    |
| ShareAlike          | Derivative databases must use ODbL                          |
| Access              | Must provide a copy of or access to the derivative database |
| Individual contents | Can be extracted and used without ODbL                      |
| Commercial use      | Allowed                                                     |

A map rendered using data from an ODbL database _can_ be released under a different license, but databases using that
data **must** use ODbL.<br/>
One can build commercial products on top of ODbL data without the copyleft reaching the final product.

## Further readings

- [Creative Commons]
- [Choose a license]

### Sources

- [CC FAQ]
- [CC license versions]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Apache]: #apache
[CC]: #creative-commons
[MIT]: #mit
[odbl]: #open-database-license

<!-- Upstream -->
[creative commons]: https://creativecommons.org/
[choose a license]: https://choosealicense.com/

<!-- Others -->
[CC FAQ]: https://creativecommons.org/faq/
[CC FAQ / Can I apply a Creative Commons license to software?]: https://creativecommons.org/faq/#can-i-apply-a-creative-commons-license-to-software
[CC license versions]: https://wiki.creativecommons.org/wiki/License_Versions
