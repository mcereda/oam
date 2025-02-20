# LoRa

FIXME

Acronym for _Long Range_.

Physical layer for wireless communication networks.<br/>
Includes the modulation technique used for long-range, low-power communication.

LoRa is the radio signal that transmits the data over the air using spread spectrum technology.

Ensures long-distance communication and robust data transmission using Chirp Spread Spectrum (CSS) modulation. It is
responsible for the low-level radio transmission.

Deals with the physical transmission of data over the air. It is concerned with the signal characteristics and the
method of transmitting data.

Focuses on LoRa chipsets and their ability to transmit data to the cloud over long distances using minimal power.

Does not include security mechanisms; it is purely a physical layer technology.

LoRa is the radio signal that carries the data, and LoRaWAN is the communication protocol that controls and defines how
that data is communicated across the network.

LoRa is a wireless modulation technique derived from Chirp Spread Spectrum (CSS) technology. It encodes information on
radio waves using chirp pulses - similar to the way dolphins and bats communicate! LoRa modulated transmission is robust
against disturbances and can be received across great distances.

LoRa is ideal for applications that transmit small chunks of data with low bit rates. Data can be transmitted at a
longer range compared to technologies like WiFi, Bluetooth or ZigBee. These features make LoRa well suited for sensors
and actuators that operate in low power mode.

LoRa can be operated on the license free sub-gigahertz bands, for example, 915 MHz, 868 MHz, and 433 MHz. It also can be
operated on 2.4 GHz to achieve higher data rates compared to sub-gigahertz bands, at the cost of range. These
frequencies fall into ISM bands that are reserved internationally for industrial, scientific, and medical purposes.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [LoRaWAN](#lorawan)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<!-- Uncomment if used
<details>
  <summary>Setup</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## LoRaWAN

FIXME

Acronym for _Long Range Wide Area Network_.

Network standard and system architecture for managing communication between LoRaWAN devices and the network server.

Defines the communication standard and system architecture at the MAC (Medium Access Control) layer.

Registered specification for low power, wide area networking.

Designed to wirelessly connect battery operated _things_ to the Internet in regional, national or global networks.<br/>
Targets key Internet of Things (IoT) requirements like bi-directional communication, end-to-end security, mobility and
localization services.

Operates in **unlicensed** radio frequency bands.

Known for having long-range capabilities (up to 15 km in rural areas), low power consumption, and the ability to connect
a large number of devices to a single network.

Manages device communication, data rates, and battery life, overseeing how data is sent and received, including
security, data integrity, and the overall network structure.

Encompasses the entire network stack, including network management, communication protocols, and application interfaces,
ensuring data is properly routed and devices are managed efficiently.

Includes end-devices, gateways, network servers, and application servers, coordinating how data is relayed, managed, and
utilized across the network.

Implements security measures like encryption and device authentication to protect data integrity and privacy.

LoRaWAN is a Media Access Control (MAC) layer protocol built on top of LoRa modulation. It is a software layer which
defines how devices use the LoRa hardware, for example when they transmit, and the format of messages.

The Things Network is powered by The Things Stack, which is a LoRaWAN network server that receives messages from
LoRaWAN devices.

The LoRaWAN protocol is developed and maintained by the [LoRa Alliance].

## Further readings

- [LoRa Alliance]
- [The Things Network]

### Sources

- [What are LoRa and LoRaWAN?]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[lora alliance]: https://lora-alliance.org/
[the things network]: https://www.thethingsnetwork.org/
[what are lora and lorawan?]: https://www.thethingsnetwork.org/docs/lorawan/what-is-lorawan/
