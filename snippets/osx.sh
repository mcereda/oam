#!sh

# Set the host's name.
scutil --set 'ComputerName' "$(defaults read '/Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName')"
scutil --set 'HostName' "$(defaults read '/Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName')"
scutil --set 'LocalHostName' "$(defaults read '/Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName')"

# Clear the DNS cache.
sudo dscacheutil -flushcache; sudo killall -HUP 'mDNSResponder'
