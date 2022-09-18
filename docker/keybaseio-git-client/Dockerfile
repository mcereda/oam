FROM keybaseio/client:stable

RUN apt-get update \
    && apt-get install -y \
         bindfs \
         git-lfs \
    && rm -rf /var/lib/apt/lists/*

# `bindfs` requires the mountpoint to exist.
ARG MOUNTPOINT='/repos.rw'
RUN mkdir -p "$MOUNTPOINT"
