# meta-dynamicdevices

Common core for Dynamic Devices Yocto board support

# Boards

## Jaguar Sentai

AI audio STT and TTS development platform

# Sound Support

## TAS2563 audio playback

The TAS2563 audio codec is used for output. Currently we've back ported an older TI driver as a kernel module. In future we plan to migrate to a backport of the newer TAS2781 driver.

The driver downloads a pre-built audio firmware binary to the TAS2563 (`/lib/firmware/tas2563_uCDSP.bin`). There is also a calibration file which is not currently supported.

The firmware can be built with the TI graphical tool for Windows which can be found [here](https://www.ti.com/tool/PUREPATHCONSOLE]).
 
Further resources can be found [here](https://www.ti.com/product/TAS2563?keyMatch=TAS2563).

The driver for this is a module which loads as `snd_soc_tas2563` (use `lsmod` to view)

We blacklist automatic loading of audio drivers in `/etc/modprobe.d/blacklist.conf` as otherwise card IDs can change depending on load order. Instead a systemd service `audio-driver` runs on startup and executes `/usr/bin/load-audio-drivers.sh` to load in the relevant drivers

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

# Networking Support

Run `ifconfig` to view the wlan0 device (there is no wired ethernet)

Run the following to add a WiFi connection

```
nmcli con add type wifi con-name DoES $CONNECTIONAME "$SSID" 802-11-wireless-security.key-mgmt WPA-PSK 802-11-wireless-security.psk "$PASSWORD" ifname wlan
```

To see connection status use:

```
nmcli
```

If a Quectel modem module is installed it is posssible to see the modem ID with:

```
mmcli -L
```

Then use this to get the modem status

```
mmcli -m $MODEM_ID
```

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

# Useful Scripts

## Board Test

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
