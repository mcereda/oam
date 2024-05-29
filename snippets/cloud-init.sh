#!/usr/bin/env sh

##
# Re-run everything.
##

# 1. Clean the existing configuration.
sudo cloud-init clean --logs

# 2. Detect local data sources.
sudo cloud-init init --local

# 3. Detect any data source requiring the network and run the 'initialization' modules.
sudo cloud-init init

# 4. Run the 'configuration' modules.
sudo cloud-init modules --mode='config'

# 5. Run the 'final' modules.
sudo cloud-init modules -m 'final'

# All together now!
sudo cloud-init clean --logs
sudo cloud-init init --local
sudo cloud-init init
sudo cloud-init modules --mode='config'
sudo cloud-init modules -m 'final'
