#!/usr/bin/env sh

is_strictly_false () {
	if [[ "$1" =~ '0|^[Ff][Aa][Ll][Ss][Ee]$|^[Nn][Oo]?$|^$' ]]
	then
		true
	else
		false
	fi
}
is_strictly_true () {
	if [[ "$1" =~ '1|^[Tt][Rr][Uu][Ee]$|^[Yy]([Ee][Ss])?$' ]]
	then
		# 0 as in "function ended successfully"
		true
	else
		false
	fi
}
