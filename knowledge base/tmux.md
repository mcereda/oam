# Tmux

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

There are 3 main objects: _sessions_, _windows_, and _panes_.

Sessions are collections of one or more windows managed as a single unit.<br/>
One can have any number of sessions active at one time, but one is typically only attached to one of them.<br/>
Each session has a **single** active window.

Windows contain and are split into one or more panes.<br/>
Windows can be thought of as tabs in browsers.<br/>
Each window has a **single** currently active pane and allows to switch to any pane it manages.<br/>
Windows are shown in the bar and the current one is marked with a `*` sign by default.<br/>
Windows can be split into panes vertically or horizontally in a tiling fashion.

Each pane is a split in one window and has its own active terminal session.<br/>
Only one pane is active and can be interacted with at any time.

Enter commands to Tmux by using the _prefix key_ (`ctrl + b` by default), followed by the command.<br/>
See usage for details.

<details>
  <summary>Installation and configuration</summary>

```sh
# Install.
brew install 'tmux'

# Get the default settings.
# Might need to run from inside a sessions.
# Specify a null configuration file so that tmux ends up printing whatever is hard-coded in its source.
tmux -f '/dev/null' show-options -s
tmux -f '/dev/null' show-options -g
tmux -f '/dev/null' list-keys
```

The configuration file is `$HOME/.tmux.conf` or `$XDG_CONFIG_HOME/tmux/tmux.conf`.

```conf
set -g default-terminal "screen-256color"   # set the default terminal mode to 256 colors
set -g history-limit 100000                 # set the scrollback size
set -g mouse on                             # enable mouse control (clickable windows, panes, resizable panes)
set -g xterm-keys on                        # pass xterm keys through

setw -g automatic-rename on   # rename the window to reflect the current program
set -g renumber-windows on    # renumber all windows when a window is closed
```

</details>
<details>
  <summary>Usage</summary>

```sh
# Reload settings.
tmux source '/path/to/config.file'

# Start sessions if none is attached.
tmux

# Create new named sessions.
tmux new -s 'session-name'

# List active sessions.
tmux list-session
tmux ls

# Attach to the most recent session.
tmux attach
tmux a

# Attach to specific sessions.
tmux attach -t named-session
```

| Key combination                   | Effect                                                     |
| --------------------------------- | ---------------------------------------------------------- |
| `ctrl + b`                        | actuate                                                    |
| `ctrl + b`, then `d`              | detach from the current session                            |
| `ctrl + b`, then `s`              | list active sessions                                       |
| `ctrl + b`, then `w`              | list active sessions with preview window                   |
| `ctrl + b`, then `c`              | create a **new** window                                    |
| `ctrl + b`, then `n`              | pass to the **next** window                                |
| `ctrl + b`, then `p`              | pass to the **previous** window                            |
| `ctrl + b`, then `0` to `9`       | pass to the window identified by that number               |
| `ctrl + b`, then `"`              | split the current window with a **horizontal** line        |
| `ctrl + b`, then `%`              | split the current window with a **vertical** line          |
| `ctrl + b`, then arrow key        | switch to the pane pointed to by the arrow key's direction |
| `ctrl + b`, then `{`              | switch to the pane left to the current one                 |
| `ctrl + b`, then `}`              | switch to the pane right to the current one                |
| `ctrl + b`, then `q`, then number | switch to the pane identified by the number                |
| `ctrl + b`, then `z`              | toggle full screen for the current pane                    |
| `ctrl + b`, then `!`              | turn the current pane into a window                        |
| `ctrl + b`, then `x`              | close the current pane                                     |

</details>
<details>
  <summary>Real world use cases</summary>

```sh
# Dedicate sessions to commands.
# Attaches to the session if it already exists, or creates it otherwise.
# Closes the session once the command finishes.
tmux new-session -As 'gitlab-upgrade' "dnf update 'gitlab-ee'"

# Operate on a background session from another one.
tmux new-session -d -S 'session-name'
tmux send-keys -t 'session-name': "command" "Enter"
tmux capture-pane -t 'session-name': -S - -E - -p | cat -n
tmux kill-session -t 'session-name'
```

</details>

## Further readings

- [Github]
- [Documentation]
- [Tmux Plugin Manager]

### Sources

- [Tmux cheat sheet & quick reference]
- [Tmux has forever changed the way I write code]
- [Sending simulated keystrokes in Bash]
- [Is it possible to send input to a tmux session without connecting to it?]
- [devhints.io]
- [hamvocke/dotfiles]
- [Default Tmux config]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[documentation]: https://github.com/tmux/tmux/wiki/
[github]: https://github.com/tmux/tmux
[tmux plugin manager]: https://github.com/tmux-plugins/tpm

<!-- Others -->
[default tmux config]: https://unix.stackexchange.com/questions/175421/default-tmux-config#342975
[devhints.io]: https://devhints.io/tmux
[hamvocke/dotfiles]: https://github.com/hamvocke/dotfiles/blob/master/tmux/.tmux.conf
[is it possible to send input to a tmux session without connecting to it?]: https://unix.stackexchange.com/questions/409861/is-it-possible-to-send-input-to-a-tmux-session-without-connecting-to-it#409863
[sending simulated keystrokes in bash]: https://superuser.com/questions/585398/sending-simulated-keystrokes-in-bash#1606615
[tmux cheat sheet & quick reference]: https://tmuxcheatsheet.com/
[tmux has forever changed the way i write code]: https://www.youtube.com/watch?v=DzNmUNvnB04
