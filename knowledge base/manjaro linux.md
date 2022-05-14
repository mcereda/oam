# Manjaro GNU/Linux

## Repositories

To ensure continued stability and reliability, Manjaro uses its own dedicated software branches rather than relying on those provided by Arch:

- **unstable**: synced several times a day with Arch's package releases; only a subset of them are modified to suit Manjaro; people using this branch need to have the skills to get themselves out of trouble; thanks to the feedback from these users, many issues are caught and fixed at this level; the very latest software is be located here, and using this branch is usually safe but - in rare cases - may cause issues with your system
- **testing**: this branch is the second line of defense; users living in this branch refine the work done by users in the _unstable_ branch by providing further feedback on the packages they receive as updates
- **stable**: packages which land here have gone through roughly a couple of weeks testing by users using the _unstable_ and _testing_ branches; these packages are usually free of any problems

One can use the [branch comparison] tool to check in what branch a package is available.

## Printing

```sh
pamac install manjaro-printer
sudo gpasswd -a ${USER} sys
sudo systemctl enable --now cups.service

# configure printers in ui
pamac install system-config-printer
```

## Further readings

- [Branch comparison]
- [Switching branches]
- [Printing]

[branch comparison]: https://manjaro.org/branch-compare
[printing]: https://wiki.manjaro.org/index.php/Printing
[switching branches]: https://wiki.manjaro.org/index.php/Switching_Branches

## Sources

- [Kde Plasma 5.23 not updating]

[kde plasma 5.23 not updating]: https://forum.manjaro.org/t/kde-plasma-5-23-not-updating/88297/4
