#!sh

# Set the host's name.
scutil --set 'ComputerName' "$(defaults read '/Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName')"
scutil --set 'HostName' "$(defaults read '/Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName')"
scutil --set 'LocalHostName' "$(defaults read '/Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName')"

# Clear the DNS cache.
sudo dscacheutil -flushcache; sudo killall -HUP 'mDNSResponder'

# Create custom DNS resolvers.
cat <<-EOF | sudo tee /etc/resolver/lan
domain lan
search lan
nameserver 192.168.1.254
nameserver 192.168.1.1
EOF
sudo dscacheutil -flushcache; sudo killall -HUP 'mDNSResponder'
scutil --dns | grep -C '3' '192.168.1.254'

# Try resolving names.
dscacheutil -q 'host' -a 'name' '192.168.1.35'
dscacheutil -q 'host' -a 'name' 'gitlab.lan'