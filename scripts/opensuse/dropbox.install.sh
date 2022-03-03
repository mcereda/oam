#!/bin/sh

# sources:
# - https://www.dropbox.com/install-linux

# No packages available
# Headless installation needed

cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
cd bin && wget -O dropbox.py "https://www.dropbox.com/download?dl=packages/dropbox.py" && chmod u+x dropbox.py && cd -
dropbox.py start  # or ~/.dropbox-dist/dropboxd
