#!/bin/zsh

if ! [[ -d "$(xcode-select -p)" ]];
then
	xcode-select --install
fi
