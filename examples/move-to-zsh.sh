#!/usr/bin/env sh

sudo pamac install fzf oh-my-zsh zsh zsh-autosuggestions zsh-syntax-highlighting
# sudo dnf install zsh-syntax-highlighting zsh-autosuggestions fzf

chsh --shell "$(which zsh)" "$USER"
cp --backup /usr/share/oh-my-zsh/zshrc ~/.zshrc

sed -Ei 's/#*\s*(ZSH_THEME)=.*/\1="refined"/' ~/.zshrc
sed -Ei 's/#*\s*(COMPLETION_WAITING_DOTS)=.*/\1="true"/' ~/.zshrc
sed -Ei 's/#*\s*(HIST_STAMPS)=.*/\1="yyyy-mm-dd"/' ~/.zshrc
# set plugins=() to (git minikube terraform)
