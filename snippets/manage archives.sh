#!/usr/bin/env sh

# `tar -a` guesses the compression algorithm from the archive extension

# Create archives
tar czvf "/tmp/prometheus-data-$(date +'%s-%F-%H-%m-%S').tar.gz" '/var/lib/prometheus/data'
tar cjpvf 'docs.tar.bz2' "${HOME}/Documents" "${HOME}/Downloads" 'docs.txt'

# List the contents of archives
tar tf "/tmp/prometheus-data-1718104097-2024-06-11-11-06-17.tar.gz"
tar tf 'kubectl.tar' 'kubectl'

# Test archives by reading their contents or extracting them to stdout.
tar tf 'archive.tar' > '/dev/null'
tar tOf 'archive.tar' > '/dev/null'

# Extract archives
tar xf 'portage-latest.tar.xz' -C '/mnt/gentoo/usr'
tar xpf 'stage3-amd64-'*'.tar.xz' --checkpoint '250'
