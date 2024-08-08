#!/usr/bin/env fish

argparse -s \
	'c/command=' \
	'D/debug' \
	'e/executor=' \
	'p/path=+' \
	'r/recursive' \
	't/threads=' \
-- $argv
or return

if ! set -q '_flag_executor'
	set '_flag_executor' 'parallel'
end
if ! set -q '_flag_path'
	set '_flag_path' "$PWD"
end
if ! set -q '_flag_recursive'
	set '_flag_recursive' '-r'
end
if ! set -q '_flag_threads'
	set '_flag_threads' (nproc)
end

if set -q '_flag_debug'
	echo "
		command: $_flag_command
		debug: $_flag_debug
		executor: $_flag_executor
		path: $_flag_path
		recursive: $_flag_recursive
		threads: $_flag_threads
		argv: $argv
	" | column -t
end

if test "$_flag_recursive" = '-r' || test "$_flag_recursive" = '--recursive'
	if set -q '_flag_debug'
		echo 'DEBUG: recursive test returned true'
	end
	set repositories (find $_flag_path -type 'd' -name '.git' -exec dirname {} +)
else
	if set -q '_flag_debug'
		echo 'DEBUG: recursive test returned false'
	end
	set repositories $_flag_path
end

if set -q '_flag_debug'
	echo "DEBUG: repositories: $repositories"
end

switch $_flag_executor
	case 'parallel'
		if ! which -s parallel
			echo "Error: GNU parallel not found" >&2
			return
		end
		parallel --color-failed -j "$_flag_threads" --tagstring "{/}" "git -C {} $_flag_command" ::: $repositories
	case 'xargs'
		echo  $repositories | xargs -tP "$_flag_threads" -I{} git -C "{}" $_flag_command
	case '*'
		echo "Error: $runner not supported" >&2
		return
end
