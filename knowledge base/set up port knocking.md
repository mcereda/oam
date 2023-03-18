# Set up port knocking

Technique where a daemon keeps listening on specific ports for a specific sequence of connections.<br/>
When the correct sequence is used, the daemon issues a configured command, usually to open a defined port for the client only.

This is frequently used to open the SSH port in a server for a specific client.

## Further readings

- [Knockd]

<!-- internal references -->
[knockd]: knockd.md
