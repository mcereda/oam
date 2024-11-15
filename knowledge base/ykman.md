# `ykman`

CLI tool for YubiKey management.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
apt-add-repository 'ppa:yubico/stable' && apt install 'yubikey-manager'
brew install 'ykman'
pip install --user 'yubikey-manager'
pkg install 'py38-yubikey-manager'
snap install 'ykman'

source <(_YKMAN_COMPLETE='bash_source' ykman | sudo tee '/etc/bash_completion.d/ykman')

# Uninstall when installed via pgk installer on OS X
sudo rm -rf '/usr/local/bin/ykman' '/usr/local/ykman'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Print the executable's version
ykman --version
ykman -v

# Enable debug mode
ykman --log-level 'DEBUG' …
ykman -l 'DEBUG' --log-file 'path/to/file.log' …

# Specify the YukiKey to use
ykman --device '01234567' …
ykman -d '01234567' …

# List connected YubiKeys
ykman list
ykman list --serials

# Show information about YubiKeys
ykman info
ykman -d '01234567' info --check-fips

# Set OTP and FIDO mode
ykman config mode 'OTP+FIDO'

# Set CCID only mode and use touch to eject the smart card
ykman config mode 'CCID' --touch-eject

# Disable PIV over NFC
ykman config nfc --disable 'PIV'

# Enable all applications over USB
ykman config usb --enable-all

# Generate and set a random application lock code
ykman config set-lock-code --generate

# Run Python scripts
ykman script 'script.py'
ykman script 'script.py' '123456' 'indata.csv'

# Show OATH status
ykman oath info
ykman -d '01234567' oath info

# List OATH accounts
ykman oath accounts list

# Add OATH accounts
ykman oath accounts add 'account-name' 'secret' --touch

# Generate OATH codes for accounts
ykman oath accounts code 'account-regex'

# Rename OATH accounts
ykman oath accounts rename 'account-regex' 'new-account-name'

# Delete OATH accounts
ykman oath accounts delete 'account-regex'

# Reset OATH data
ykman oath info

# Show FIDO status
# FIDO --> FIDO2 and U2F
ykman fido info

# List stored FIDO credentials
ykman fido credentials list --pin '123456'

# Delete FIDO credentials
ykman fido credentials delete 'credential-id'

# List registered fingerprints
ykman fido fingerprints list
ykman fido fingerprints list --pin '123456'

# Register fingerprints
ykman fido fingerprints add 'fingerprint-name' --pin '123456'

# Delete stored fingerprints
ykman fido fingerprints delete 'fingerprint-id'

# Reset FIDO data
ykman fido reset
ykman fido reset --force

# Change FIDO PIN
ykman fido access change-pin --pin '123456' --new-pin '654321'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Codebase]
- [Documentation]

### Sources

- [Configuring YubiKey for Challenge-Response with YubiKey Manager (ykman)]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/Yubico/yubikey-manager
[documentation]: https://docs.yubico.com/software/yubikey/tools/ykman/Using_the_ykman_CLI.html

<!-- Others -->
[configuring yubikey for challenge-response with yubikey manager (ykman)]: https://bytefreaks.net/gnulinux/bash/configuring-yubikey-for-challenge-response-with-yubikey-manager-ykman
