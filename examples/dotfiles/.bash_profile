################################################################################
## ~/.bash_profile
##
## There are 3 different types of shells in Bash:
## - the login shell;
## - the interactive non-login shell;
## - the non-interactive non-login shell.
## Login shells read /etc/profile, and only the first one found between
## '~/.bash_profile', '~/.bash_login' and '~/.profile' in this order.
## Interactive non-login shells read /etc/bashrc and ~/.bashrc.
## Non-interactive non-login shell read the file which name is the value of the
## '$BASH_ENV' variable.
## In this setup, ~/.bash_profile sources ~/.bashrc, which means that all
## changes made here will also take effect in a login shell.
##
## This file is sourced by all Bash *login* shells on startup.
################################################################################

# Load the user's interactive settings.
# This lines are recommended by the Bash info pages.
: "${BASHRC=$HOME/.bashrc}"
if [[ -r "$BASHRC" ]]
then
        source "$BASHRC"
fi
