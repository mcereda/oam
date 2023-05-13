#!/usr/bin/env sh

set -e

if [ "$(id -ru)" -eq 0 ]
then
	echo "Run this again as 'root'"
	exit 1
fi

# Package management

pkg bootstrap
pkg update
pkg install -y \
	'sudo' \
	'vim' \
	'zsh' 'zsh-autosuggestions' 'zsh-completions' 'zsh-navigation-tools' 'zsh-syntax-highlighting'

# Non-'root' user management

pw groupmod 'wheel' -m 'username'
sed -i '.bak' -E 's|# (%wheel ALL=\(ALL:ALL\) ALL)|\1|' '/usr/local/etc/sudoers'
visudo -cf '/usr/local/etc/sudoers'
cat > '/home/username/.zshrc' <<-EOF
	source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
	source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
	source /usr/local/share/zsh-navigation-tools/zsh-navigation-tools.plugin.zsh

	HISTFILE=~/.histfile
	HISTSIZE=100000
	SAVEHIST=100000
	bindkey -e

	zstyle :compinstall filename ~/.zshrc
	autoload -Uz compinit
	compinit
EOF
chown 'username':'usergroup' '/home/username/.zshrc'
chmod 'u=rw,go=r' '/home/username/.zshrc'
chpass -s "$(grep 'bin/zsh' '/etc/shells')" 'username'
