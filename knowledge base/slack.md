# Slack

1. [TL;DR](#tldr)
1. [Add custom emoji](#add-custom-emoji)
1. [Give aliases to existing emojis](#give-aliases-to-existing-emojis)
1. [Apps](#apps)
1. [Incoming webhooks](#incoming-webhooks)
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
curl -X 'POST' -H 'Content-type: application/json' \
  --data '{"text": "Hello, World!"}' \
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

## Apps

Direct links:

- [Create a new App](https://api.slack.com/apps?new_app=1).

## Incoming webhooks

Refer [Sending messages using incoming webhooks] and [Setting Up Slack Webhook URL Simplified 101].

1. Enable Incoming Webhooks for a Slack app.<br/>
   _Features_ → _Incoming Webhooks_ → _Activate Incoming Webhooks_.
1. Create a new Webhook URL and authorize it (or request authorization for it).
1. Install the app in the workspace.
1. Send a test request to the webhook.

   ```sh
   curl -X 'POST' -H 'Content-type: application/json' \
     'https://hooks.slack.com/services/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' --data '{"text": "Hello, World!"}'
   ```

## Further readings

- [Website]
- [Sending messages using incoming webhooks]
- [Posting messages using curl]

### Sources

- [Slackmojis]
- [Slack Notifications for Ansible Tower (AWX)]
- [Setting Up Slack Webhook URL Simplified 101]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[posting messages using curl]: https://api.slack.com/tutorials/tracks/posting-messages-with-curl
[sending messages using incoming webhooks]: https://api.slack.com/messaging/webhooks
[website]: https://slack.com/

<!-- Others -->
[setting up slack webhook url simplified 101]: https://hevodata.com/learn/slack-webhook-url/
[slack notifications for ansible tower (awx)]: https://mpolinowski.github.io/docs/DevOps/Ansible/2021-04-30-ansible-tower-slack-notifications/2021-04-30/
[slackmojis]: https://slackmojis.com/
