#!/usr/bin/env fish

function git-all
	if ! which -s parallel
		echo "GNU parallel not found" >&2
		return
	end

	argparse -s 'c/command=' 'p/path=+' 'r/recursive' -- $argv
	or return

	if test "$_flag_recursive" = '-r' || test "$_flag_recursive" = '--recursive'
		set repositories (find $_flag_path -type 'd' -name '.git' -exec dirname {} +)
	else
		set repositories $_flag_path
	end

	parallel --color-failed --tagstring "{/}" "git -C {} $_flag_command" ::: $repositories
end
