# Home Assistant Add-on: SiliconLabs Zigbee/OpenThread Multiprotocol Add-on

Zigbee/OpenThread Multiprotocol container for Silicon Labs based radios such as
Home Assistant Yellow, Home Assistant SkyConnect, and Home Assistant Connect ZBT-1.

![Supports armv7 Architecture][armv7-shield]
![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]

## About

This addon is based on official SiliconLabs Zigbee/OpenThread Multiprotocol Add-on 
from Home assistant dev team. 

This add-on allows you to use Zigbee and OpenThread protocol simultaneous on a
single Silicon Labs based radio. The radio needs the RCP Multi-PAN firmware
installed to support multiple IEEE 802.15.4 Personal Area Networks (PAN). The
addon has been tested with EFR32 Series 2 based radios.

The RPC Mutli-PAN firmware should be based on GeckoSDK 4.4.x and newer.

Supports firmwares v7.4.x.x and v8.0.x.x.

Also supports BLE (not yet implemented)

[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
