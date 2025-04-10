# Slack

1. [TL;DR](#tldr)
1. [Add custom emoji](#add-custom-emoji)
1. [Give aliases to existing emojis](#give-aliases-to-existing-emojis)
1. [Use incoming webhooks for notifications](#use-incoming-webhooks-for-notifications)
1. [Use bots for notifications](#use-bots-for-notifications)
1. [Create apps](#create-apps)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
brew install --cask 'slack'
mas install '803453959'
```

CLI:

```sh
brew install --cask 'slack-cli' \
&& slack login
```

Authorization data will be saved to `~/.slack/credentials.json`.

</details>

<details>
  <summary>Usage</summary>

```sh
# Login.
slack login

# List authorized accounts.
slack auth list
slack list
```

```sh
# Send notifications to channels using the APIs.
curl --request 'POST' --url 'https://slack.com/api/chat.postMessage?pretty=1' \
  --header 'Authorization: Bearer xoxb-012345678901-0123456789012-abcdefghijklmnopqrstuvwx' \
  --header 'Content-type: application/json' --data '{"channel": "C04K1234567", "text": "Hello, World!"}'

# Send notifications to channels using incoming webhooks.
curl --request 'POST' --url 'https://hooks.slack.com/services/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' \
  --header 'Content-type: application/json' --data '{"text": "Hello, World!"}'
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

## Use incoming webhooks for notifications

Refer [Sending messages using incoming webhooks] and [Setting Up Slack Webhook URL Simplified 101].

1. Enable Incoming Webhooks for a Slack app.<br/>
   _Features_ → _Incoming Webhooks_ → _Activate Incoming Webhooks_.
1. Create a new Webhook URL and authorize it (or request authorization for it).
1. Install (or request an higher entity to install) the app in the workspace.<br/>
   App details → _Settings_ → _Install App_ → _OAuth Tokens_.<br/>
1. Send a test request to the webhook:

   ```sh
   curl --request 'POST' --url 'https://hooks.slack.com/services/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' \
     --header 'Content-type: application/json' --data '{"text": "Hello, World!"}'
   ```

## Use bots for notifications

Refer [Automating Slack Notifications: Sending Messages as a Bot with Python].

1. [Create a new Slack App][create apps].
1. Select _From Scratch_.
1. Enter a name (e.g., `test bot`) and select a workspace for it.
1. Add the required OAuth scopes (e.g. `chat:write`).<br/>
   App details → _Features_ → _OAuth & Permissions_ → _Scopes_ → _Bot Token Scopes_.
1. Install (or request an higher entity to install) the app in the workspace.<br/>
   App details → _Settings_ → _Install App_ → _OAuth Tokens_.<br/>
   This will automatically generate an OAuth token for the app. Note that token down.
1. Add the app to the channels it needs to interact with.
   Channel details → _Integrations_ tab → _Apps_ section → _Add apps_.
1. Try sending messages using the app's OAuth token:

   ```sh
   curl --request 'POST' --url 'https://slack.com/api/chat.postMessage?pretty=1' \
     --header 'Authorization: Bearer xoxb-012345678901-0123456789012-abcdefghijklmnopqrstuvwx' \
     --header 'Content-type: application/json' --data '{"channel": "C04K1234567", "text": "Hello, World!"}'
   ```

## Create apps

[Direct link](https://api.slack.com/apps?new_app=1).

## Further readings

- [Website]
- [Sending messages using incoming webhooks]
- [Posting messages using curl]
- [CLI]

### Sources

- [Slackmojis]
- [Slack Notifications for Ansible Tower (AWX)]
- [Setting Up Slack Webhook URL Simplified 101]
- [How to quickly get and use a Slack API bot token]
- [Automating Slack Notifications: Sending Messages as a Bot with Python]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[create apps]: #create-apps

<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[cli]: https://tools.slack.dev/slack-cli/
[posting messages using curl]: https://api.slack.com/tutorials/tracks/posting-messages-with-curl
[sending messages using incoming webhooks]: https://api.slack.com/messaging/webhooks
[website]: https://slack.com/
[how to quickly get and use a slack api bot token]: https://api.slack.com/tutorials/tracks/getting-a-token

<!-- Others -->
[automating slack notifications: sending messages as a bot with python]: https://medium.com/@sid2631/automating-slack-notifications-sending-messages-as-a-bot-with-python-2beb6c16cd8c
[setting up slack webhook url simplified 101]: https://hevodata.com/learn/slack-webhook-url/
[slack notifications for ansible tower (awx)]: https://mpolinowski.github.io/docs/DevOps/Ansible/2021-04-30-ansible-tower-slack-notifications/2021-04-30/
[slackmojis]: https://slackmojis.com/
