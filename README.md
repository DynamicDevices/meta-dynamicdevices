# meta-dynamicdevices

Common core for Dynamic Devices Yocto board support

# Board Support

## Jaguar Sentai

AI audio STT and TTS development platform. For details see [here](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Jaguar-Sentai-Board).

To build `lmp-dynamicdevces-base` with Kas:

`KAS_MACHINE=imx8mm-jaguar-sentai kas-container build kas/lmp-dynamicdevices-base.yml`

To program the image:

`cd program && ./program_linux.sh`

## Jaguar Phasora

MACHINE=imx8mm-jaguar-phasora is building and under TEST

## Jaguar Handheld

MACHINE=imx8mm-jaguar-handheld is building and under TEST

## i.MX8ULP EVK

MACHINE=imx8ulp-lpddr4-evk is building and under TEST

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
