# Signal

Open source application for secure messaging.

Available for [Android][android app], [iOS][iOS app], Linux, Mac OS X, and Windows.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Conversations are end-to-end encrypted.

Each and every one-to-one chat has its own unique _safety number_.<br/>
It allows verifying one is communicating with the correct contact.

When a safety number is marked as verified, a checkmark will appear in the chat header by that contact's name.<br/>
It will remain like that unless the safety number changes or one manually changes the verification status.

Signal notifies the user whenever a safety number has changed.

When the safety number changes, it's as if one changed the locks and keys for the conversation.<br/>
Messages sent _before_ the safety number changed use the old locks, and as such they will **not** be deliverable.

SMS/MMS messaging _was_ supported in Android systems, but it has been removed
[since october 2022][removing sms support from signal android].

<!-- Uncomment if used
<details>
  <summary>Setup</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Website]
- [Codebase]

### Sources

- [Help]
- [Removing SMS support from Signal Android]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[Android app]: https://play.google.com/store/apps/details?id=org.thoughtcrime.securesms
[Codebase]: https://github.com/signalapp
[Help]: https://support.signal.org/hc/en-us
[iOS app]: https://apps.apple.com/app/id874139669
[Removing SMS support from Signal Android]: https://signal.org/blog/sms-removal-android/
[Website]: https://signal.org/

<!-- Others -->
