FROM keybaseio/client:stable

RUN apt-get update \
    && apt-get install -y \
         bindfs \
         git-lfs \
         nfs-common \
    && apt-get install -y --no-install-recommends samba \
    && rm -rf /var/lib/apt/lists/*

# `bindfs` requires the mountpoint to exist.
ARG BINDFS_MOUNTPOINT='/repos.rw'
RUN mkdir -p "$BINDFS_MOUNTPOINT"
