# Armbian

Ultralight Linux distribution optimized for custom ARM, RISC-V or Intel hardware.<br/>
Based on Debian.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

[PI4b image]. Write with [BalenaEtcher].

`root` password and default user created on first boot by the init script.

```sh
# Connect to WiFi networks.
nmtui-connect
nmtui-connect 'SSID'

# Adjust hardware features.
sudo armbian-config

# Install Docker.
sudo mkdir -p '/etc/apt/keyrings'
curl -fsSL 'https://download.docker.com/linux/debian/gpg' | sudo gpg --dearmor -o '/etc/apt/keyrings/docker.gpg'
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bullseye stable" | sudo tee '/etc/apt/sources.list.d/docker.list' > /dev/null
sudo apt update
sudo apt install -y 'docker-ce' 'docker-compose-plugin'
sudo docker run --rm 'hello-world'
sudo usermod -aG 'docker' "$USER"
```

## Further readings

- [Website]
- [Documentation]
- [Github] account
- [Debian] GNU/Linux
- [Raspberry Pi OS]

## Sources

- [How to run Docker]

<!--
  References
  -->

<!-- Upstream -->
[documentation]: https://docs.armbian.com/
[github]: https://github.com/armbian
[how to run docker]: https://docs.armbian.com/User-Guide_Advanced-Features/#how-to-run-docker
[pi4b image]: https://www.armbian.com/rpi4b/
[website]: https://www.armbian.com/

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[debian]: debian.md
[raspberry pi os]: raspberry%20pi%20os.md

<!-- Others -->
[balenaetcher]: https://etcher.balena.io/
