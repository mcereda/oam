#!/usr/bin/env sh

sudo dnf list --available --showduplicates 'gitlab-runner'

sudo dnf check-update --bugfix --security

sudo dnf upgrade --security --sec-severity 'Critical' --downloadonly
sudo dnf -y upgrade --security --sec-severity 'Important'
