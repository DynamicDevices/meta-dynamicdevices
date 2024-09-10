# meta-dynamicdevices

Common core for Dynamic Devices Yocto board support

# Boards

## Jaguar Sentai

AI audio STT and TTS development platform

# Sound Support

## TAS2563 audio playback

The TAS2563 audio codec is used for output. Currently we've back ported an older TI driver as a kernel module. In future we plan to migrate to a backport of the newer TAS2781 driver.

The driver downloads a pre-built audio firmware binary to the TAS2563 (`/lib/firmware/tas2563_uCDSP.bin`). There is also a calibration file which is not currently supported.

The firmware can be built with the TI graphical tool for Windows which can be found [here](https://www.ti.com/tool/PUREPATHCONSOLE).
 
Further resources can be found [here](https://www.ti.com/product/TAS2563?keyMatch=TAS2563).

The driver for this is a module which loads as `snd_soc_tas2563` (use `lsmod` to view)

We blacklist automatic loading of audio drivers in `/etc/modprobe.d/blacklist.conf` as otherwise card IDs can change depending on load order. Instead a systemd service `audio-driver` runs on startup and executes `/usr/bin/load-audio-drivers.sh` to load in the relevant drivers

### ALSA

When loaded `aplay -l` can be executed to show device details

```
root@imx8mm-jaguar-sentai-7130a09dab86563:/var/rootdirs/home/fio# aplay -l            
**** List of PLAYBACK Hardware Devices ****
card 1: tas2563audio [tas2563-audio], device 0: 30030000.sai-tas2563 ASI1 tas2563 ASI1-0 [30030000.sai-tas2563 ASI1 tas2563 ASI1-0]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
```

To play a sample wav file the following command can be used

```
aplay -Dhw:1,0 -r 48000 -c 2 sample.wav 
```

NOTE: Currently when using the hardware device directly only 2 channnels of 48kHz audio are supported.

### PulseAudio

We need to be running audio within docker containers. We seem to be able to use ALSA but some .NET code fails with ALSA. So we've added PulseAudio to the host OS mage and can use this instead of ALSA.

There are PulseAudio equivalents to ALSA record and playback utilities. For example

```
parecord file.wav
paplay file.wav
```

There is also a command line control utility, for example

```
pactl list sources
pactl list sinks
pactl list modules
```

NOTE: That the pulseaudio server runs as non-root `fio` user. It's not possible to interact with the server as the root user and this will fail.

The docker container needs to have access to the host os pulse audio socket and dbus. An example `docker-compose.yml` configuration to achieve this looks something like this

```
version: '2'
services:
  Example:
    build: .
    image: hub.foundries.io/dynamic-devices/example:latest
    devices:
      - /dev/snd:/dev/snd
    environment:
      - PULSE_SERVER=unix:/tmp/pulseaudio.socket
      - PULSE_COOKIE=/tmp/pulseaudio.cookie
    volumes:
      - "/tmp:/tmp"
      - "/run/dbus/system_bus_socket:/run/dbus/system_bus_socket"
    restart: always
    privileged: true
```

TODO: We should support cookies for authentication but this is not yet implemented. Instead we allow unauthenticated to the host pulseaudio server

To provide the socket in a known place, `/tmp/pulseaudio.socket` we have a script that runs the following command on start-up

```
pactl load-module module-native-protocol-unix socket=/tmp/pulseaudio.socket auth-anonymous=true
```

Then you can enter a docker container configured as above and run the `paplay` commands or similar

SECURITY NOTE: That usually PulseAudio would run within a user session. This makes sense for desktop/laptop systems but is non-ideal for embedded systems. Instead we run PulseAudio in the systemwide configuration so we don't have to worry about user login. There are potentially some security and other issues with running in this configuration. These should be noted and can be found [here](https://www.freedesktop.org/wiki/Software/PulseAudio/Documentation/User/SystemWide/).

# Networking / Radio Support

## WiFi

Run `ifconfig` to view the wlan0 device (there is no wired ethernet)

Run the following to add a WiFi connection

```
nmcli con add type wifi con-name DoES $CONNECTIONAME "$SSID" 802-11-wireless-security.key-mgmt WPA-PSK 802-11-wireless-security.psk "$PASSWORD" ifname wlan
```

To see connection status use:

```
nmcli
```

## Cellular

If a Quectel modem module is installed it is posssible to see the modem ID with:

```
mmcli -L
```

Then use this to get the modem status

```
mmcli -m $MODEM_ID
```

## Bluetooth / BLE

TBD

## 802.15.4 / Thread / Matter

TBD

# Sensors

## SHT40-AD1F-R2 Temperature & Humidity

This is implemented as an I2C device using the SHT4X IIO driver. The `lm-sensors` framework is installed to the image. To see sensor details use `sensors`.

```
root@imx8mm-jaguar-sentai-7130a09dab86563:~# sensors
sht4x-i2c-2-44
Adapter: 30a40000.i2c
temp1:        +32.0 C  
humidity1:     33.0 %RH
```

## LIS2DH12 Accelerometer

```
root@imx8mm-jaguar-sentai-7130a09dab86563:~# cat /sys/bus/iio/devices/iio\:device0/name 
lis2dh12_accel
root@imx8mm-jaguar-sentai-7130a09dab86563:~# echo 400 > /sys/bus/iio/devices/iio\:device0/sampling_frequency
root@imx8mm-jaguar-sentai-7130a09dab86563:~# cat /sys/bus/iio/devices/iio\:device0/in_accel_x_raw 
336
root@imx8mm-jaguar-sentai-7130a09dab86563:~# cat /sys/bus/iio/devices/iio\:device0/in_accel_x_raw 
-8
```

## STTS22H Temperature

The STT22H driver is implemented within the IIO subsystem. To check the temperature you can use:

```
root@imx8mm-jaguar-sentai-7130a09dab86563:~# cat /sys/bus/iio/devices/iio\:device1/name 
stts22h
root@imx8mm-jaguar-sentai-7130a09dab86563:~# cat /sys/bus/iio/devices/iio\:device1/in_temp_ambient_raw 
3073
root@imx8mm-jaguar-sentai-7130a09dab86563:~# cat /sys/bus/iio/devices/iio\:device1/in_temp_ambient_scale 
10.000000000
```

TODO: These numbers don't seem quite right?

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

## LED testing

- Pulse RGBW LED intensity "heartbeat" `test-leds-hb.sh`
- Rotate R, G, B, W in ring `test-leds-rc.sh`

# Board Testing (fiotest)

TBD

# Power

Note that USB-A does not provide enough power for the system when the speaker is operating. The unit should be powered from an appropriate USB-C adaptor.

# Reflashing a board

See details [here](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Flashing-a-Jaguar-board-with-a-Yocto-Embedded-Linux-image).
