#!/usr/bin/env sh

# Poweroff immediately
sudo shutdown now
sudo shutdown -h now
sudo shutdown -P +0 --no-wall

# Reboot in 1 minutes
sudo shutdown -r '+15'
sudo shutdown -r '+15' 'heyo, reboot time!'

# Show pending shutdown actions and time if any
sudo shutdown --show

# Cancel pending shutdowns
sudo shutdown -c
