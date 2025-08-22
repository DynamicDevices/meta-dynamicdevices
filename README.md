# meta-dynamicdevices

Common core for Active Edge Solutions "Edge" Yocto board support

Support for local kas build is a work in progress. Some notes:

- it is expected that `kas-container` is used for builds
- the `lmp-dynamicdevices-base.yml` file expects three persisent folders to be present and mapped outside the container
- there is a script `kas-build-base.sh` which sets up folders with permissions for the container to access

NOTE: We're building an unsigned image for testing but there's an issue with the build process that requires you to copy your `factory-keys` folder and sub-directories to `build/conf/factory-keys` for now. If you see the error below this is the problem.

```
| make[2]: *** No rule to make target '/build/conf/factory-keys/opteedev.key', needed by '/build/tmp/work/imx8mm_jaguar_phasora-lmp-linux/optee-test/3.21.0-r0/build/ta/create_fail_test/c3f6e2c0-3548-11e1-b86c-0800200c9a66.ta'.  Stop.
```

# Building Yocto firmware images

## Edge AI

AI audio STT and TTS development platform. For details see [here](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-AI-Board).

To build `lmp-dynamicdevices-base` with Kas:

`KAS_MACHINE=imx8mm-jaguar-sentai ./kas-build-base.sh`

To program the image:

`KAS_MACHINE=imx8mm-jaguar-sentai ./program.sh`

## Edge EV

Energy metering and control platform. For details see [here](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-EV-Board).

To build `lmp-dynamicdevices-base` with Kas:

`KAS_MACHINE=imx8mm-jaguar-sentai ./kas-build-base.sh`

To program the image:

`KAS_MACHINE=imx8mm-jaguar-sentai ./program.sh`

## Edge GW

Flexible communications gateway platform. For details see [here](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-GW-Board).

To build `lmp-dynamicdevices-base` with Kas:

`KAS_MACHINE=imx8mm-jaguar-inst ./kas-build-base.sh`

To program the image:

`KAS_MACHINE=imx8mm-jaguar-inst ./program.sh`

## Edge eInk (i.MX93)

Next-generation low-power display platform with i.MX93 processor. For details see [here](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-eInk-Board).

To build `lmp-dynamicdevices-base` with Kas:

`KAS_MACHINE=imx93-jaguar-eink ./kas-build-base.sh`

To program the image:

`KAS_MACHINE=imx93-jaguar-eink ./program.sh`

**Important Notes**:
- SE05X secure element support is currently disabled for this machine to avoid build conflicts with CAAM crypto drivers
- The machine builds successfully without SE05X features
- If SE05X support is needed, the `CFG_CRYPTO_DRIVER` configuration conflict needs to be resolved in the OP-TEE recipe

## i.MX8ULP EVK

TBD

# Manufacturing Tools Support

For i.MX93 platforms, manufacturing tool (mfgtool) images can be built for board programming and recovery.

## Building mfgtool Images

To build mfgtool images for i.MX93:

```bash
KAS_MACHINE=imx93-11x11-lpddr4x-evk ./kas-build-mfgtools.sh
```

This creates special boot images that can be used with NXP's UUU (Universal Update Utility) tool for board recovery and initial programming.

The mfgtool build:
- Uses the `lmp-mfgtool` distro instead of `lmp`
- Generates compressed initramfs images (`.cpio.gz`) instead of fitImages
- Creates specialized bootloader configurations for manufacturing

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
