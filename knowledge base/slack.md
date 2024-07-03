# Slack

1. [TL;DR](#tldr)
1. [Add custom emoji](#add-custom-emoji)
1. [Give aliases to existing emojis](#give-aliases-to-existing-emojis)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
brew install --cask 'slack'
mas install '803453959'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Send notifications to channels
curl -X POST -H 'Content-type: application/json' \
  --data '{"text": "Staging DB restore completed successfully"}' \
  'https://hooks.slack.com/services/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'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Add custom emoji

Check out [slackmojis] for some common reactions.

1. Go to <https://{{org-name}}.slack.com/customize/emoji>.
1. Select _Add Custom Emoji_.
1. Upload the image.
   Supported formats: GIF, JPG, PNG.
1. Give it a name.

## Give aliases to existing emojis

1. Go to <https://{{org-name}}.slack.com/customize/emoji>.
1. Select _Add Alias_.
1. Choose the image.
1. Give it an alias.

## Further readings

- [Website]

### Sources

- [Slackmojis]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[website]: https://slack.com/

<!-- Others -->
[slackmojis]: https://slackmojis.com/
