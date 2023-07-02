################################################################################
## ~/.zshenv
##
## This file is sourced by *all* zsh shells on startup.
################################################################################

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
# Basic utility aliases and functions.
#
# Used to simplify checks later.
# Needed in all shells.
# Ordered alphabetically and by dependencies.
########################################

alias disable-xtrace='unsetopt xtrace'
alias enable-xtrace='setopt xtrace'
alias is-shell-interactive='[[ -o interactive ]]'
alias is-shell-login='[[ -o login ]]'

# Print the whole current environment.
alias printallenv='setopt posixbuiltins && set'

to-lower () {
	echo "${1:l}"
}

to-upper () {
	echo "${1:u}"
}

is-true () {
	# Needs to return 0 or 1 and not `true` or `false`.
	# Input's case is lowered to save on match options.

	local LOWERED_INPUT="$(to-lower "$1")"
	[[ "$LOWERED_INPUT" =~ '^1|on|true|yes$' ]]
}

# Make PATHs' entries unique for better performances.
typeset -aU {f,info,man,}path

########################################
# Shell configuration.
#
# https://zsh.sourceforge.io/Doc/Release/Options.html
########################################

# Require 'cd' to change directory.
unsetopt auto_cd

########################################
# Utility aliases and functions.
#
# Ordered and grouped by dependencies.
########################################

alias decomment='grep -Ev "^#|^$"'

alias please='sudo'

########################################
# Applications' settings and shortcuts.
########################################

####################
# Python.
####################

# See also:
# - https://docs.python.org/3/using/cmdline.html#environment-variables

PYTHONCACHE=1

####################
# GnuPG.
####################

# Integrate with the SSH agent.
export SSH_AUTH_SOCK="$(/opt/homebrew/bin/gpgconf --list-dirs 'agent-ssh-socket')"
/opt/homebrew/bin/gpgconf --launch 'gpg-agent'

# Integrate with Pinentry.
export GPG_TTY="$(tty)"
