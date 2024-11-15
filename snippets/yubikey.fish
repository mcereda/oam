#!/usr/bin/env fish

brew install --cask 'yubico-yubikey-manager'


###
# ykman CLI
# ------------------
###

brew install 'ykman'

ykman list
ykman -d '00000000' info

ykman oath accounts list


###
# just dump, still needs tests
###

ssh-keygen -t 'ed25519-sk' -O 'resident' -O 'verify-required' -C 'Yubikey 5C NFC'
