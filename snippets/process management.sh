#!/usr/bin/env sh

# https://askubuntu.com/questions/180336/how-to-find-the-process-id-pid-of-a-running-terminal-program
# https://bash.cyberciti.biz/guide/Sending_signal_to_Processes

# Find process IDs
pidof 'gitlab-runner'
pgrep 'gitlab-runner'
# Limit search to specific owners
pgrep -u 'root,daemon' 'sshd'


# List available signals
kill -l

# Send signals to processes
kill -9 '1234'
kill -KILL '1234'
kill -SIGKILL '1234'
kill -s 'SIGHUP' '3969'
pkill -KILL 'firefox'
pkill --signal 'HUP' 'prometheus'
killall -s 'SIGKILL' 'firefox-bin'
