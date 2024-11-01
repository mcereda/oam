#!/usr/bin/env fish

###
# just dump, still needs tests
###

ssh-keygen -t 'ed25519-sk' -O 'resident' -O 'verify-required' -C "Yubikey 5C NFC"
