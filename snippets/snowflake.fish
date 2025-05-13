#!/usr/bin/env fish

curl -C '-' -LfSO \
	--url 'https://sfc-repo.snowflakecomputing.com/snowflake-cli/darwin_arm64/3.7.2/snowflake-cli-3.7.2-darwin-arm64.pkg' \
&& sudo installer -pkg 'snowflake-cli-3.7.2-darwin-arm64.pkg' -target '/' \
&& ln -swiv '/Applications/SnowflakeCLI.app/Contents/MacOS/snow' "$HOME/bin/snow"
