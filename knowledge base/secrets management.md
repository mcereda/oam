# Secrets management

1. [TL;DR](#tldr)
1. [The problem at hand](#the-problem-at-hand)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

_Vaults_ and _secrets managers_ are centralized solution that manage secrets.<br/>
Examples: [HashiCorp Vault], [OpenBao], [Bitwarden Secrets Manager], [1Password Secrets Automation], [CyberArk Conjur],
[Akeyless].

_Secrets orchestration platforms_ offer a transparent access point for users while being a vault itself and/or syncing
secrets between multiple other vaults and secrets managers.<br/>
Examples: [Doppler], [Infisical], [Pulumi ESC].

Solutions should be easy to use and get **out** of their users' way, so that they can be more easily adopted.

## The problem at hand

Secrets are usually bad managed in local development environments.<br/>
The process of grabbing all required secrets on local machines is often manual, cumbersome, and prone to errors.<br/>
This causes the onboarding process to slow down, and encourages developers to follow insecure practices when sharing
secrets.

Saving secrets in (possibly encrypted) git-tracked files (e.g. `.env`) still lacks the level of syncing teams might
require.<br/>
Even if notified, developers don't usually pull the updated files nor make all the required adjustments immediately,
likely being then forced to lose time debugging issues due to deprecated or changed data.

Even with a working synchronization process, it's common for developers to accidentally leak secrets as part of
commits.<br/>
As soon as a secret is part of the git history, it becomes a security issue and it is hard to get it removed
properly.<br/>
Though git hooks exist, it is likely for them to be misconfigured or simply skipped (`git commit --no-verify`).

Having a centralized solution to manage secrets can come to the rescue, as long as it is adopted profusely.<br/>
The only way this can happen is if that solution is easy to use and manage, and get **out** of the way of
developers.<br/>
_Vaults_ and _secrets managers_ usually do a good job for this.

Tools might also integrate with or support only one or a small set of solutions, limiting the choice of platforms.<br/>
It would be good to have a way to sync secrets between multiple platforms. Even better, to use a single access point to
abstract the sync process and make it transparent.<br/>
This is what _secrets orchestration platforms_ try to solve.

## Further readings

- [HashiCorp Vault]
- [Infisical]

### Sources

- [Secrets Management Tools: The Complete 2025 Guide]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[HashiCorp Vault]: hashicorp%20vault.md
[Infisical]: infisical.md
[Pulumi ESC]: pulumi.md#esc

<!-- Files -->
<!-- Others -->
[1Password Secrets Automation]: https://1password.com/developers/secrets-management
[Akeyless]: https://www.akeyless.io/
[Bitwarden secrets manager]: https://bitwarden.com/products/secrets-manager/
[CyberArk Conjur]: https://www.conjur.org/
[Doppler]: https://www.doppler.com/
[OpenBao]: https://openbao.org/
[Secrets Management Tools: The Complete 2025 Guide]: https://www.pulumi.com/blog/secrets-management-tools-guide/
