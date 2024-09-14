#!/usr/bin/env fish

nix-env -i --attr 'nixos.kubectl' 'nixos.k9s' 'nixos.helm'

sudo nixos-rebuild switch
