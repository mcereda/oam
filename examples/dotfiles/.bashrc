################################################################################
## ~/.bashrc
##
## There are 3 different types of shells in Bash:
## - the login shell;
## - the interactive non-login shell;
## - the non-interactive non-login shell.
## Login shells read '/etc/profile', and only the first one found between
## '~/.bash_profile', '~/.bash_login' and '~/.profile' in this order.
## Interactive non-login shells read '/etc/bashrc' and '~/.bashrc'.
## Non-interactive non-login shells read the file which name is the value of the
## '$BASH_ENV' variable.
## In this setup, '~/.bash_profile' sources '~/.bashrc', which means that all
## changes made here will also take effect in a login shell.
##
## This file is sourced by all *interactive* Bash shells on startup, including
## some apparently interactive shells such as `scp` and `rcp` which can't
## tolerate any output.
## Make sure this doesn't display anything or bad things will happen!
##
## It is recommended to put language settings in '~/.bash_profile',
## '~/.bash_login' or '~/.profile' rather than here, as multilingual X sessions
## would not work properly if '$LANG' is overridden in every subshell.
##
## References:
## - https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html
################################################################################

# Automatically logout after 60 minutes of inactivity.
export TMOUT="3600"

########################################
# Ensure primary XDG variables are set.
########################################

: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${XDG_CACHE_HOME:=${HOME}/.cache}"
: "${XDG_DATA_HOME:=${HOME}/.local/share}"
: "${XDG_STATE_HOME:=${HOME}/.local/state}"
: "${XDG_DATA_DIRS:=/usr/local/share:/usr/share}"
: "${XDG_CONFIG_DIRS:=/etc/xdg}"

########################################
# Ensure PATH contains common binary directories.
# Prefer user's and local paths.
########################################

export PATH="/Users/user/.local/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

########################################
# Basic utility aliases and functions.
#
# Used to simplify checks later.
# Needed in all shells.
# Ordered alphabetically and by dependencies.
########################################

alias disable-xtrace='set +o xtrace'
alias enable-xtrace='set -o xtrace'

# Print the whole current environment.
alias printallenv='set -o posix && set'

is-symlink-broken () { [[ ! -e "$1" ]] ; }

is-shell-interactive () {
	# From Bash's manpage:
	#   '$PS1' is set and '$-' includes 'i' if the shell is interactive.

	[[ $- =~ i ]] || [[ -t 0 ]]
}

is-shell-login () {
	# From Bash's manpage:
	#   A login shell is one whose first character of argument zero is a '-', or
	#   one started with the '--login' option.

	[[ $0 =~ ^- ]] || [[ $(shopt login_shell | cut -f 2) == 'on' ]]
}

to-lower () {
	# Bash3 has no built-in means to convert case of a string, fallback to `tr`.
	echo "$(echo "$1" | tr '[:upper:]' '[:lower:]')"
}

to-upper () {
	# Bash3 has no built-in means to convert case of a string, fallback to `tr`.
	echo "$(echo "$1" | tr '[:lower:]' '[:upper:]')"
}

is-true () {
	# Needs to return 0 or 1 and not `true` or `false`.
	# Input's case is lowered to save on match options.

	local LOWERED_INPUT="$(to-lower "$1")"
	[[ "$LOWERED_INPUT" =~ ^1|on|true|yes$ ]]
}

# If this is a non-interactive shell, do nothing else.
# There is no need to set anything past this point for scp and rcp, and it's
# important to refrain from outputting anything in those cases.
is-shell-interactive || return

########################################
# Shell configuration.
########################################

# Check the window size of the current terminal window after each command.
# If necessary, update the values of the LINES and COLUMNS variables.
shopt -s checkwinsize

# If Readline is being used, do not attempt to search PATH for possible
# completions when the line is empty and wait a long time for this.
shopt -s no_empty_cmd_completion

# Add "/" to links to directories in autocompletion.
set mark-symlinked-directories on

####################
# History management.
####################

# Erase duplicates and ignore lines starting with spaces.
HISTCONTROL="ignorespace:erasedups"

# Number of lines or commands allowed in the history file.
HISTFILESIZE=100000

# Number of lines or commands stored in memory as the history of the current
# session.
HISTSIZE=50000

# Format how the history's entries are stored.
HISTTIMEFORMAT="%Y-%m-%d %T  "

# Attempt to save all lines of a multi-line command in the same history entry.
# This allows easy re-editing of such commands.
shopt -s cmdhist

# Append the history entries in memory to the HISTFILE when exiting the shell,
# rather than just overwriting the file.
shopt -s histappend

# If readline is being used, load the results of history substitution into the
# editing buffer, allowing further modification before execution.
shopt -s histverify

########################################
# Utility aliases and functions.
#
# Ordered and grouped by dependencies.
########################################

alias decomment='grep -Ev "^#|^$"'
alias redo='$(history -p !!)'

alias please='sudo'
alias sedo='sudo redo'

ask-for-confirmation () {
	is-true "$DEBUG" && enable-xtrace

	read -p 'Continue? ' REPLY

	if ! is-true "$REPLY"
	then
		echo "aborting"
		return 1
	fi

	local RETURN_VALUE=$?
	is-true "$DEBUG" && disable-xtrace
	return $RETURN_VALUE
}

swap () {
	is-true "$DEBUG" && enable-xtrace

	if [[ ! $# -eq 2 ]]
	then
		echo "Usage: $0 file1 file2"
		echo "Example: $0 /etc/resolv.conf resolv.new"
		return 1
	fi

	local TMPFILE="tmp.$$"
	mv "$1" "$TMPFILE"
	mv "$2" "$1"
	mv "$TMPFILE" "$2"

	local RETURN_VALUE=$?
	is-true "$DEBUG" && disable-xtrace
	return $RETURN_VALUE
}

########################################
# Applications settings and shortcuts.
########################################

# Set the default editor.
export EDITOR="/usr/bin/vim"

# Enable colors.
alias grep='grep --color=always'
alias ls='ls -G'

####################
# GnuPG.
####################

# Integrate with the SSH agent.
export SSH_AUTH_SOCK="$(/opt/homebrew/bin/gpgconf --list-dirs 'agent-ssh-socket')"
/opt/homebrew/bin/gpgconf --launch 'gpg-agent'

# Integrate with Pinentry.
export GPG_TTY="$(tty)"

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
