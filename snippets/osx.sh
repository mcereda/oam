#!/usr/bin/env sh

# Set the host's name
scutil --set 'ComputerName' "$(defaults read '/Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName')"
scutil --set 'HostName' "$(defaults read '/Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName')"
scutil --set 'LocalHostName' "$(defaults read '/Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName')"


# Bypass Gatekeeper for currently installed versions
xattr -c '/Applications/Spotify.app'

# Bypass Gatekeeper for all versions of apps
xattr -d 'com.apple.quarantine' '/Applications/LibreWolf.app'
xattr -d 'com.apple.quarantine' '/Applications/Zen Browser.app'


# Clear the DNS cache
sudo dscacheutil -flushcache; sudo killall -HUP 'mDNSResponder'

# Create custom DNS resolvers
cat <<-EOF | sudo tee /etc/resolver/lan
domain lan
search lan
nameserver 192.168.1.254
nameserver 192.168.1.1
EOF
sudo dscacheutil -flushcache; sudo killall -HUP 'mDNSResponder'
scutil --dns | grep -C '3' '192.168.1.254'

# Try resolving names
dscacheutil -q 'host' -a 'name' '192.168.1.35'
dscacheutil -q 'host' -a 'name' 'gitlab.lan'


# Change the number of columns and rows in the springboard
defaults write 'com.apple.dock' 'springboard-columns' -int '9'
defaults write 'com.apple.dock' 'springboard-rows' -int '7'
# Need to be followed by a restart of the modified component
killall 'Dock'


# Install Xcode cli tools if missing
[[ -d "$(xcode-select --print-path)" ]] || xcode-select --install

# Install 'brew' and its bundle
# Uses the user's global Brewfile if found
command -v 'brew' > '/dev/null' || /bin/bash -c "$(curl -fsSL 'https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh')"
[[ -r "${HOME}/.Brewfile" ]] && brew bundle --global --no-lock

# Install macports
if ! command -v 'port' > '/dev/null'
then
	curl -C- -o '/tmp/macports.pkg https://github.com/macports/macports-base/releases/download/v2.7.2/MacPorts-2.7.2-12-Monterey.pkg'
	sudo installer -pkg '/tmp/macports.pkg' -target '/'
fi
