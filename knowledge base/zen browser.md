# Zen browser

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
brew install --cask 'zen-browser'
```

</details>

<details>
  <summary>Split tabs</summary>

1. Select the desired ones:
   - Hold `CTRL` or `CMD`, then left-click to select only specific tabs, or
   - Left-click 2 tabs while holding the Shift key to select all tabs in between.
1. Right click one of the selected tabs.
1. Choose the _Split x Tabs_ contextual menu option.
   X will be the number of selected tabs.

The default Split View layout is a grid. Change it by pressing the 🔗 button in the top address bar (usually between the
tab container indicator and the favourites' star button).

</details>

<details>
  <summary>Reduce the window's border</summary>

1. Go to `about:config`.
1. Look for `zen.theme.content-element-separation`.
1. Set the padding value to whatever one wants.<br/>
   Defaults to `8`.

</details>

## Further readings

- [Website]
- [Codebase]
- [Documentation]

### Sources

- [How do I use the Split View feature?]
- [Reduce Window Border Thickness]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[Codebase]: https://github.com/zen-browser/desktop
[Documentation]: https://docs.zen-browser.app/
[How do i use the split view feature?]: https://docs.zen-browser.app/faq#how-do-i-use-the-split-view-feature
[Reduce Window Border Thickness]: https://github.com/zen-browser/desktop/discussions/3452#discussioncomment-13363156
[Website]: https://zen-browser.app/
