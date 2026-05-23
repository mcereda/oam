# Slack

1. [TL;DR](#tldr)
1. [Add custom emoji](#add-custom-emoji)
1. [Give aliases to existing emojis](#give-aliases-to-existing-emojis)
1. [Use incoming webhooks for notifications](#use-incoming-webhooks-for-notifications)
1. [Use bots for notifications](#use-bots-for-notifications)
1. [Create apps](#create-apps)
1. [Create slash commands](#create-slash-commands)
   1. [Verifying the signing secret](#verifying-the-signing-secret)
   1. [3-second ack + async pattern](#3-second-ack--async-pattern)
      1. [Managing the deadline in AWS Lambda](#managing-the-deadline-in-aws-lambda)
1. [Update an existing app's manifest](#update-an-existing-apps-manifest)
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

Slash commands are workspace-wide. Once an app with a slash command is installed to a workspace, the command is
immediately available in **every** channel, no per-channel opt-in needed.<br/>
Channel membership for bots only matters for `chat.postMessage` (unprompted bot messages), not for slash command
response flows using `response_url`.

Slack's App Management UI can inject fields (`pkce_enabled`, `is_mcp_enabled`) into a stored manifest, but their own
manifest validator does **not** recognize them as valid schema fields. SHould one ever see a manifest validation error
one did not introduce, the stored manifest may have been silently mutated. The fix is to re-paste the canonical source,
save it, and reinstall the app.

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

## Create slash commands

1. Go to [api.slack.com/apps] → _Create New App_ → _From an app manifest_.
1. Select the workspace.
1. Paste the app manifest's YAML, then click _Create_.

   <details style='padding: 0 0 1rem 1rem'>
     <summary>Example using an AWS Lambda</summary>

   ```yml
   ---
   display_information:
     name: AWS EC2 lister
     description: List EC2 instances
     background_color: "#66ff00"

   features:
     bot_user:
       display_name: AWS EC2 lister
       always_online: false
     slash_commands:
       - command: /ec2-list-running
         url: https://abcd0123.execute-api.eu-west-1.amazonaws.com/prod/slack/ec2/running
         description: List running EC2 instances
         usage_hint: >-
           env:<environment-name> | name:<name-tag>
         should_escape: true

   oauth_config:
     scopes:
       bot:
         - commands

   settings:
     org_deploy_enabled: false
     socket_mode_enabled: false
     token_rotation_enabled: false
   ```

   </details>

   `features.bot_user` must be present whenever `features.slash_commands` is defined: the manifest validator rejects it
   otherwise.<br/>
   `always_online: false` is correct for HTTP-only apps (no WebSocket/RTM connection).

1. Install the app to the Workspace → _Allow_.<br/>
   Reinstall the app after approval until an OAuth token appears. It will exist in a Schrodinger state until then.
1. Add all needed collaborators to the App.<br/>
   They will **not** be able to access it otherwise.

### Verifying the signing secret

Slack signs every slash command request with HMAC-SHA256. Find the signing secret at:
App details → **Basic Information** → **App Credentials** → **Signing Secret**.

Verify it before trusting the payload:

```python
import hashlib, hmac, time

def verify_slack_signature(signing_secret: str, headers: dict, raw_body: str) -> bool:
    timestamp = headers['X-Slack-Request-Timestamp']
    if abs(time.time() - int(timestamp)) > 300:
        return False  # reject replays older than 5 minutes
    base = f'v0:{timestamp}:{raw_body}'.encode()
    expected = 'v0=' + hmac.new(signing_secret.encode(), base, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, headers['X-Slack-Signature'])
```

- The body must be the **raw**, **unencoded** request body (before `parse_qs` or JSON decode).
- Use `hmac.compare_digest` (and not `==`) to avoid timing attacks.
- For AWS API Gateway + Lambda proxy: without `binaryMediaTypes` configured, `isBase64Encoded` is `False` and the body
  arrives as a plain string; no decoding is needed before HMAC. If binary media types are set, and `isBase64Encoded`
  is `True`, base64-decode first; verification always fails otherwise.

### 3-second ack + async pattern

Slack requires a HTTP response within 3 seconds. When an operation could take longer, consider this pattern:

1. Verify the signature, parse the command, enqueue or self-invoke the actual work asynchronously.
1. Return HTTP 200 immediately with an **ephemeral** ack.
1. Post the result to `response_url` once work completes.

_Ephemeral_ responses `{"response_type": "ephemeral", "text": "…"}` are only visible to the caller.<br/>
_In-channel_ responses `{"response_type": "in_channel", "text": "…"}` are visible to everyone in the channel.

Validate the `response_url` starts with `https://hooks.slack.com/` before posting to it: Slack always sends URLs in this
form, and skipping the check lets a channel member craft a slash command with an arbitrary URL.

#### Managing the deadline in AWS Lambda

The cleanest way to honour the 3-second deadline when calling AWS Lambda functions specifically is by _self-invocation_.
The synchronous invocation from Slack does the **lightweight** work (verify the signature, parse, ack), then fires a
second `InvocationType=Event` call to the **same** Lambda for the **actual** work.<br/>
A sentinel field (e.g. `isAsync: True`) on the payload can distinguish the two paths in the handler.

```python
def handler(event, context):
    if event.get('isAsync'):
        return _handle_async(event)
    # verify, parse, self-invoke, ack go here

def handle_slack_request(event, context):
    """
    Lightweight work goes here.
    Verify signature, parse, validate response_url, etc.
    """
    try:
        lambda_client.invoke(
            FunctionName=context.function_name,   # runtime name, not hardcoded
            InvocationType='Event',
            Payload=json.dumps({
                'isAsync': True,
                'resources': resources,
                'response_url': response_url,
            }).encode(),
        )
    except Exception:
        return message_slack('Failed to queue work, try again later.')
    return message_slack(f'Starting {len(resources)} resources.')
```

> [!important]
> The IAM role executing the Lambda requires `lambda:InvokeFunction` on the lambda's ARN, for self-invoke to work:
>
> ```json
> {
>   "Sid": "AllowSelfInvoke",
>   "Effect": "Allow",
>   "Action": "lambda:InvokeFunction",
>   "Resource": "arn:aws:lambda:<region>:<account>:function:<function-name>"
> }
> ```
>
> Use `context.function_name` for the target. Hardcoding the function name breaks, when the Lambda is renamed or
> deployed in blue/green mode.

## Update an existing app's manifest

1. Go to the App's details → _Features_ → _App Manifest_.
1. Make the changes, then save.
1. Reinstall the App.

## Further readings

- [Website]
- [Sending messages using incoming webhooks]
- [Posting messages using curl]
- [Verifying requests from Slack]
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
[api.slack.com/apps]: https://api.slack.com/apps
[cli]: https://tools.slack.dev/slack-cli/
[how to quickly get and use a slack api bot token]: https://api.slack.com/tutorials/tracks/getting-a-token
[posting messages using curl]: https://api.slack.com/tutorials/tracks/posting-messages-with-curl
[sending messages using incoming webhooks]: https://api.slack.com/messaging/webhooks
[verifying requests from slack]: https://docs.slack.dev/authentication/verifying-requests-from-slack
[website]: https://slack.com/

<!-- Others -->
[automating slack notifications: sending messages as a bot with python]: https://medium.com/@sid2631/automating-slack-notifications-sending-messages-as-a-bot-with-python-2beb6c16cd8c
[setting up slack webhook url simplified 101]: https://hevodata.com/learn/slack-webhook-url/
[slack notifications for ansible tower (awx)]: https://mpolinowski.github.io/docs/DevOps/Ansible/2021-04-30-ansible-tower-slack-notifications/2021-04-30/
[slackmojis]: https://slackmojis.com/
