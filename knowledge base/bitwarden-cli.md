# Bitwarden CLI

CLI to access and manage Bitwarden vaults.

## TL;DR

```sh
# Install on OS X.
brew install 'bitwarden-cli'

# Generate shell completion.
# Only ZSH is supported at the time of writing.
bw completion --shell 'zsh'

# Get help on a command.
bw --help
bw 'command' --help
bw help 'command'

# Check you are logged in.
bw login --check

# Return the session key.
bw login --raw

# Login.
bw login
bw login 'user_email' 'master_password' --method '1' --code '249213'
bw login 'user_email' --passwordenv 'BW_MASTER_PASSWORD'
bw login --passwordfile 'path/to/file.txt'
bw login --sso

# Unlock the vault.
export BW_SESSION='session_key'
bw unlock 'master_password'

# Lock the vault.
bw lock

# Sync.
bw sync
bw sync -f

# Get last sync's timestamp.
bw sync --last

# List entries.
bw list items
bw list items --session 'session_key'

# Display a specific entry.
bw get item 'item_name_or_id'

# Search and display entries.
bw list items --search 'github'

# Get only an attribute of an entry.
bw get password 'https://google.com'
bw get totp 'google.com'
bw get notes 'google.com'
bw get exposed 'yahoo.com'
bw get attachment 'b857igwl1dzrs2' --itemid 'entry_id' --output './photo.jpg'
bw get attachment 'photo.jpg' --itemid 'entry_id' --raw
bw get folder 'email'
bw get template 'folder'

# Create an entry.
bw create item 'eyJuYW1lIjogIkl0ZW0gTmFtZSJ9Cg=='
echo '{"name": "Item Name"}' | bw encode | bw create item
echo -n '{"name": "Item Name"}' | base64 | bw create item

# Attach a file to an existing entry.
bw create attachment --file './myfile.csv' --itemid 'entry_id'

# Edit an entry.
echo '{"name": "New Item Name"}' | bw encode | bw edit folder
bw edit folder 'folder_id' 'eyJuYW1lIjogIk5ldyBJdGVtIE5hbWUifQo='

# Delete an entry.
bw delete item 'entry_id'

# Create a folder.
bw create folder 'eyJuYW1lIjoiTXkgRm9sZGVyMiJ9Cg=='
echo '{"name": "Folder Name"}' | bw encode | bw create folder
echo -n '{"name": "Folder Name"}' | base64 | bw create folder

# Edit a folder.
echo '{"name": "New Name"}' | bw encode | bw edit folder
bw edit folder 'folder_id' 'eyJuYW1lIjogIk5ldyBOYW1lIn0K'

# Import data from a file.
bw import 'bitwardencsv' './from/source.csv'
bw import 'keepass2xml' 'keepass_backup.xml'
bw import --organizationid 'organization_id' 'keepass2xml' 'keepass_backup.xml'

# List import files' formats. 
bw import --formats

# Export data to a CSV or JSON file.
bw export
bw export 'master_password'
bw export 'master_password' --format 'json'
bw export --output './exp/bw.csv'
bw export 'master_password' --output 'bw.json' --format 'json'
bw export 'master_password' --organizationid 'organization_id'

# Export data to STDOUT.
bw --raw export

# Send something.
bw send -f './file.ext'
bw send 'text_to_send'
echo 'text to send' | bw send

# Receive something sent.
bw receive 'https://vault.bitwarden.com/#/send/rg3iuoS_Akm2gqy6ADRHmg/Ht7dYjsqjmgqUM3rjzZDSQ'

# Configure the server to use.
bw config server
bw config server 'https://bw.company.com'
bw config server 'bitwarden.com'
bw config server --api 'http://localhost:4000' --identity 'http://localhost:33656'

# Generate a password or passphrase.
bw generate
bw generate -u -l --length '18'
bw generate -ulns --length '25'
bw generate -ul
bw generate -p --separator '_'
bw generate -p --words '5' --separator 'space'

# Logout.
bw logout
```

## Sources

- [cheat.sh]

<!-- external references -->
[cheat.sh]: https://cheat.sh/bw
