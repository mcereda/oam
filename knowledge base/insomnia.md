# Insomnia

## Table of contents <!-- omit in toc -->

1. [Troubleshooting](#troubleshooting)
   1. [Manually install plugins](#manually-install-plugins)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Troubleshooting

### Manually install plugins

1. open the plugins folder in the terminal; get the path in _Preferences_ > _Plugins_ tab > _Reveal Plugins Folder_ button
1. use `npm` to install the plugin in that folder:

   ```sh
   npm i --prefix ./ insomnia-plugin-date-add
   ```

## Further readings

- [Website]
- [Documentation]
- [Inso CLI], runner for Insomnia
- [Postman], an alternative to Insomnia
- [Hoppscotch], an alternative to Insomnia
- [Bruno], an alternative to Insomnia
- [httpie], an alternative to Insomnia

## Sources

All the references in the [further readings] section, plus the following:

- [NPM install module in current directory]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[bruno]: bruno.md
[hoppscotch]: hoppscotch.md
[httpie]: httpie.md
[postman]: postman.md

<!-- Upstream -->
[documentation]: https://docs.insomnia.rest/
[inso cli]: https://docs.insomnia.rest/inso-cli
[website]: https://insomnia.rest/

<!-- Others -->
[npm install module in current directory]: https://stackoverflow.com/questions/14032160/npm-install-module-in-current-directory#45660836
