#!/usr/bin/env sh

# Install packages
pip install 'yamllint'
pip install --user 'ansible==10.1.0'
pip install -U --require-virtualenv -r 'requirements.txt' --no-cache-dir

# Upgrade packages
pip install -U 'pip'

# Upgrade the included `pip` executable on Mac OS X
~/Library/Python/3.8/bin/pip3 install --user --upgrade 'pip'

# Upgrade all currently installed packages
pip install --requirement <(pip freeze | sed 's/==/>=/') --upgrade

# Generate a list of the outdated packages
pip list --outdated

# Get the currently configured cache directory
pip cache dir

# Provide an overview of the contents of the cache
pip cache info

# List files from the 'wheel' cache
pip cache list
pip cache list 'ansible'

# Removes files from the 'wheel' cache
# Files from the 'HTTP' cache are left untouched at this time
pip cache remove 'setuptools'

# Clear all files from the 'wheel' and 'HTTP' caches
pip cache purge
