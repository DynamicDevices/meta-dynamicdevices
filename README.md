# meta-dynamicdevices

Common core for Dynamic Devices Yocto board support

Support for local kas build is a work in progress. Some notes:

- it is expected that `kas-container` is used for builds
- the `lmp-dynamicdevices-base.yml` file expects three persisent folders to be present and mapped outside the container
- there is a script `kas-build-base.sh` which sets up folders with permissions for the container to access

# Board Support

## Jaguar Sentai

AI audio STT and TTS development platform. For details see [here](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Jaguar-Sentai-Board).

To build `lmp-dynamicdevices-base` with Kas:

`KAS_MACHINE=imx8mm-jaguar-sentai ./kas-build-base.sh`

To program the image:

`KAS_MACHINE=imx8mm-jaguar-sentai ./program.sh`

## Jaguar Phasora

To build `lmp-dynamicdevices-base` with Kas:

`KAS_MACHINE=imx8mm-jaguar-phasora ./kas-build-base.sh`

To program the image:

`KAS_MACHINE=imx8mm-jaguar-phasora ./program.sh`

## Jaguar INST

To build `lmp-dynamicdevices-base` with Kas:

`KAS_MACHINE=imx8mm-jaguar-inst ./kas-build-base.sh`

To program the image:

`KAS_MACHINE=imx8mm-jaguar-inst ./program.sh`

## i.MX8ULP EVK

TBD

# Useful Scripts

## Board Info

Run the `board-info.sh` script for general board info including board unique ID (from SOC), WiFi MAC address and modem IMEI

e.g.

```
BOARD DETAILS
=============

**************************************
Machine: i.MX8MM Jaguar Sentai board
Serial: 07130A09DAB86563
WLAN MAC: dc:bd:cc:d1:80:99
Modem Present: true
Modem SIM State: state: enabled
Modem IMEI: d: 867752050572
Modem F/W: n: EM05EFAR06A06
Modem MSISDN: 46719121279982
**************************************
Done
```
# Board Testing (fiotest)

TBD

# Power

Note that USB-A does not provide enough power for the system e.g. when a speaker is operating. The unit should be powered from an appropriate USB-C adaptor.

# Reflashing a board

See details [here](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Flashing-a-Jaguar-board-with-a-Yocto-Embedded-Linux-image).
