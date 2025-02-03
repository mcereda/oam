# Chatbot

Enables using messaging program chat rooms to monitor, and respond to, operational events in AWS by processing service
notifications from SNS and forwarding them to chat rooms like Slack channels.

One can also run AWS CLI commands in chat channels using Chatbot.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Chatbot has **no** additional charge, minimum fees nor upfront commitments.<br/>
One will pay for the underlying services (SNS, SQS, CloudWatch, …).

Supports Amazon Chime, Microsoft Teams, and [Slack] at the time of writing.

<!-- Uncomment if used
<details>
  <summary>Setup</summary>

```sh
```

</details>
-->

<details>
  <summary>Usage</summary>

```sh
# List Slack workspaces.
aws chatbot describe-slack-workspaces
aws chatbot describe-slack-workspaces --query 'SlackWorkspaces'

# Show Slack channel configurations.
aws chatbot describe-slack-channel-configurations
aws chatbot describe-slack-channel-configurations --query 'SlackChannelConfigurations'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Website]
- [Documentation]
- [Slack]
- [SNS]

### Sources

- [What is AWS Chatbot?]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[slack]: ../../slack.md
[sns]: sns.md

<!-- Files -->
<!-- Upstream -->
[documentation]: https://docs.aws.amazon.com/chatbot/
[website]: https://aws.amazon.com/chatbot/
[what is aws chatbot?]: https://docs.aws.amazon.com/chatbot/latest/adminguide/what-is.html

<!-- Others -->
