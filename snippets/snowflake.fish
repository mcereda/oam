#!/usr/bin/env fish

###
# Snowflake CLI
# ------------------
###

# Install
curl -C '-' -LfSO \
	--url 'https://sfc-repo.snowflakecomputing.com/snowflake-cli/darwin_arm64/3.7.2/snowflake-cli-3.7.2-darwin-arm64.pkg' \
&& sudo installer -pkg 'snowflake-cli-3.7.2-darwin-arm64.pkg' -target '/' \
&& ln -swiv '/Applications/SnowflakeCLI.app/Contents/MacOS/snow' "$HOME/bin/snow"

# Show the configuration
cat "$HOME/Library/Application Support/snowflake/config.toml"

# Add connections
snow connection add
snow --config-file 'my_config.toml' connection add -n 'myconnection2' --account 'myaccount2' --user 'jdoe2' --no-interactive

# List connections
snow connection list

# Test connections
snow connection test
snow --config-file='my_config.toml' connection test -c 'myconnection2' --enable-diag --diag-log-path "$HOME/report"

# Set the default connection
snow connection set-default 'myconnection2'

# Execute SQL commands
snow sql


###
# Roleout
# ------------------
###

# Install
# macOS
curl -C '-' -LfSO --url 'https://github.com/Snowflake-Labs/roleout/releases/download/v2.0.1/Roleout-2.0.1-arm64.dmg' \
&& sudo installer -pkg 'Roleout-2.0.1-arm64.dmg' -target '/' \
&& sudo xattr -r -d 'com.apple.quarantine' '/Applications/Roleout.app' \
&& curl -C '-' -LfS --url 'https://github.com/Snowflake-Labs/roleout/releases/download/v2.0.1/roleout-cli-macos' \
     --output "$HOME/bin/roleout-cli" \
&& chmod 'u+x' "$HOME/bin/roleout-cli" \
&& xattr -d 'com.apple.quarantine' "$HOME/bin/roleout-cli"

# Configure access
export SNOWFLAKE_ACCOUNT='ab01234.eu-west-1' \
  SNOWFLAKE_USER='DIANE' SNOWFLAKE_PRIVATE_KEY_PATH='some-private-key-path' \
  SNOWFLAKE_WAREHOUSE='DEV_DIANE_WH' SNOWFLAKE_ROLE='ACCOUNTADMIN'

# Load objects from Snowflake
roleout-cli snowflake populateProject -o 'my_config.yml'

# Update existing configurations
roleout-cli snowflake populateProject -c 'my_config.yml' -o 'my_new_config.yml'

# Import existing objects that are defined in the configuration
roleout-cli terraform import -c 'my_config.yml'
# Just write the `terraform import` commands to a file instead of running them
roleout-cli terraform import -c 'my_config.yml' --output 'my_import_commands.sh'
roleout-cli terraform import -c 'my_config.yml' -o '/dev/stdout'
