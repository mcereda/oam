################################################################################
## ~/.zshrc
##
## This file is sourced by all *interactive* zsh shells on startup, including
## some apparently interactive shells such as scp and rcp that can't tolerate
## any output.
## Make sure this doesn't display anything or bad things will happen!
##
## It is recommended to make language settings in ~/.zprofile rather than here,
## since multilingual X sessions would not work properly if LANG is overridden
## in every subshell.
################################################################################

# Enable this and the last line to debug performance.
# zmodload zsh/zprof

########################################
# Shell configuration.
# Sane defaults that could easily be overridden later.
########################################

# If a pattern for filename generation has no matches, print an error instead of
# leaving it unchanged in the argument list.
# This also applies to file expansion of an initial '~' or '='.
setopt no_match

# Treat '#' as a comment starter instead of matching patterns.
setopt interactive_comments

# Remind compinstall where it wrote zstyle statements last time.
# This lets one run compinstall again to update them.
zstyle ':compinstall' filename ~/.zshrc

# Automatically update completions after PATH changes.
zstyle ':completion:*' rehash true

# Enable cache for completions.
zstyle ':completion:*' use-cache true

# Load extensions.
autoload -Uz bashcompinit compinit promptinit

# Enable completions.
bashcompinit
compinit

# Enable prompt management.
promptinit

# Automatically logout after 60 minutes of inactivity.
export TMOUT="3600"

####################
# History management.
####################

# The file to save the history into when an interactive shell exits.
# If unset, the history is not saved.
: "${HISTFILE:=$HOME/.zsh_history}"

# Set the number of lines or commands allowed in the history file
SAVEHIST=50000

# Set the number of lines or commands stored in memory as history list during an
# ongoing session
HISTSIZE=100000

# Append the session's history list to the history file, rather than replace it.
# Multiple parallel sessions will all have the new entries from their history
# lists added to the history file, in the order that they exit. The file will
# still be periodically re-written to trim it when the number of lines grows 20%
# beyond the value specified by $SAVEHIST
setopt append_history

# When searching for history entries in the line editor, do not display
# duplicates of a line previously found
# setopt hist_find_no_dups

# If a new command line being added to the history list duplicates an older one,
# the older command is removed from the list
setopt hist_ignore_all_dups

# Remove command lines from the history list when the first character on the
# line is a space, or when one of the expanded aliases contains a leading space.
# Only normal aliases (not global or suffix aliases) have this behavior. Note
# that the command lingers in the internal history until the next command is
# entered before it vanishes, allowing you to briefly reuse or edit the line.
# If you want to make it vanish right away without entering another command,
# type a space and press return
setopt hist_ignore_space

# Remove superfluous blanks from each command line being added to the history
setopt hist_reduce_blanks

# Omit older commands duplicating newer ones when writing out the history file
# setopts hist_save_no_dups

# Whenever the user enters a line with history expansion, perform history
# expansion and reload the line into the editing buffer instead of executing it
setopt hist_verify

########################################
# Utility aliases and functions.
#
# Ordered and grouped by dependencies.
########################################

####################
# History management.
####################

alias redo='$(history -p !!)'
alias sedo='sudo $(history -p !!)'

########################################
# Applications settings and shortcuts.
########################################

# Set the default editor.
export EDITOR="/usr/bin/vim"

# Enable colors.
alias grep='grep --color=always'
alias ls='ls -G'

####################
# SSH.
####################

alias ssh-load-keys='eval `ssh-agent` && ssh-add'

####################
# Kubernetes.
####################

alias kubectl-current-context='kubectl config current-context'

kubectl-decode () { echo "$1" | base64 -d ; }
kubectl-encode () { echo -n "$1" | base64 ; }

kubectl-nodes-with-issues () {
	kubectl get nodes -o jsonpath='{.items[]}' \
	| jq '
		{
			"node": .metadata.name,
			"issues": [
				.status.conditions[] | select(
					.status != "False" and
					.type != "Ready"
				)
			]
		} | select( .issues|length > 0 )
	' -
}
alias kubectl-nodes-with-issues-in-yaml='kubectl-nodes-with-issues | yq -y "." -'

# Reassign the expected behaviour to the delete, end and home keys.
bindkey "^[[3~" delete-char
bindkey "^[[F"  end-of-line
bindkey "^[[H"  beginning-of-line

########################################
# Configuration freeze.
# Finalize customizations and try to set the current configuration immutable.
########################################

# Clean up PATHs.
# Remove non-existing directories, follow symlinks and clean up remaining paths.
if command which realpath >/dev/null 2>&1
then
	[[ -n "${fpath[@]}" ]]    && fpath=(    $(realpath -q ${fpath[@]})    )
	[[ -n "${infopath[@]}" ]] && infopath=( $(realpath -q ${infopath[@]}) )
	[[ -n "${manpath[@]}" ]]  && manpath=(  $(realpath -q ${manpath[@]})  )
	[[ -n "${path[@]}" ]]     && path=(     $(realpath -q ${path[@]})     )
fi

# Freeze (-f) or unfreeze (-u) the tty. When the tty is frozen, no changes made
# to the tty settings by external programs will be honored by the shell, except
# for changes in the size of the screen; the shell will simply reset the
# settings to their previous values as soon as each command exits or is
# suspended.
# Freezing the tty only causes future changes to the state to be blocked.
ttyctl -f

# Enable this and the module inclusion on the first line to debug performance.
# zprof
