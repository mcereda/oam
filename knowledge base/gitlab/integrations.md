# GitLab integrations

1. [Linear](#linear)
   1. [Linear integration setup](#linear-integration-setup)
   1. [Create MRs that are recognized and automatically linked by Linear](#create-mrs-that-are-recognized-and-automatically-linked-by-linear)
   1. [Linear integration troubleshooting](#linear-integration-troubleshooting)
      1. [The integration configuration seems OK, but tickets stopped updating](#the-integration-configuration-seems-ok-but-tickets-stopped-updating)
1. [Further reading](#further-reading)

## [Linear]

### Linear integration setup

Refer Linear's documentation for [GitLab integration].

> [!important]
> The GitLab installation must be reachable from Linear's servers through the public Internet.

Linear requires an API access token to communicate with the GitLab instance.\
The access token is used both to query GitLab's API for information and to post issue linkbacks.

It can be a user's or [service account][gitlab service accounts]'s
[personal access token][gitlab personal access tokens], or a
[project-specific access token][gitlab project access tokens].\
GitLab doesn't support _bot_-like accounts, so linkbacks are created under the name of the token's owner. It's
recommended to create a new service account for Linear to act as the bot account.

The token needs the `api` or `read_api` scope.

Should one select the `read_api` scope, Linear will **not** post linkbacks to the issue upon GitLab merge requests.\
If using a project access token, that token needs the `Reporter` role or higher.

<details>
  <summary>Procedure</summary>

1. Make sure the GitLab installation is reachable from Linear's servers.\
   Their public IPs are currently `35.231.147.226`, `35.243.134.228`, `34.140.253.14`, and `34.38.87.206`.
1. \[optional but suggested] Create Linear's [service account][gitlab service accounts].
1. Create the API access token in one's GitLab instance.
1. Navigate to [Linear's _Settings_ > _Features_ > _Integrations_ > _GitLab_][linear's gitlab integration's settings].
1. Click _Enable_ to launch the set-up pop-up.
1. Enter the access token.
1. \[if self-hosted] Enter the **public** GitLab URL without any path.
1. Click Connect.
1. Linear will generate the Webhook URL after it validates the access token.
1. Copy and paste the generated URL to GitLab.\
   Do it under:

   - A **group**'s _Settings_ > _Webhooks_ to integrate **all** projects under it.
   - A **project**'s _Settings_ > _Webhooks_, to individually connect that specific project.

1. Enable the following triggers for the webhook:

   - _Push events_.
   - _Comments_.
   - _Merge request events_.
   - _Pipeline events_.

1. Ensure the _Enable SSL verification_ checkbox is checked under _SSL verification_.
1. Click _Save changes_.

</details>

### Create MRs that are recognized and automatically linked by Linear

One does need to follow a bit [Linear's documentation][link merge requests⁠] for the integration to work.

> [!NOTE]
> _Some_ steps seem to be optional, so the automation most likely depends on the MR leveraging _one or more_ of them.

The TL;DR is the following:

1. The GitLab group or project must be configured with Linear's integration's webhook.
1. Create a branch using the format configured in [Linear's GitLab integration's settings].
1. Make your changes in that branch, then push it.
1. When creating the MR for the branch:

   - Add the Linear issue's ID to the MR title.
   - Use [one or more the magic words][use a magic word] Linear requires in the description.\
     This works for linking multiple issues.

1. Enjoy the issue's status changing automatically when the MR is closed.

### Linear integration troubleshooting

> [!important]
> [Linear's support team][support@linear.app] has access to internal diagnostic logs built by their engineering team
> for debugging and system monitoring.<br/>
> Those are **not** exposed externally, nor are accessible through the Linear interface or API.

#### The integration configuration seems OK, but tickets stopped updating

Root cause: it could be that the TLS certificate used by the integrations proxy is expired.<br/>
If this is the case, [Linear's support team][support@linear.app] will be able to see logs like the following:

> ```plaintext
> Error fetching merge request from GitLab: request to https://gitlab.example.org/api/v4/projects/... failed, reason:
> certificate has expired
> ```

Solution: make sure the certificate is still valid, and renew it if not.

## Further reading

- [GitLab integration]
- [GitLab service accounts]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->

[GitLab integration]: https://linear.app/docs/gitlab
[GitLab personal access tokens]: https://docs.gitlab.com/user/profile/personal_access_tokens/
[GitLab project access tokens]: https://docs.gitlab.com/user/project/settings/project_access_tokens/
[GitLab service accounts]: https://docs.gitlab.com/user/profile/service_accounts/
[Linear's GitLab integration's settings]: https://linear.app/settings/integrations/gitlab
[Linear]: https://linear.app/
[Link Merge Requests⁠]: https://linear.app/docs/gitlab#link-merge-requests
[support@linear.app]: mailto:support@linear.app
[Use a magic word]: https://linear.app/docs/gitlab#use-a-magic-word
