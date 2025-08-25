# Edge AI Board (imx8mm-jaguar-sentai) Project Context

## Project Overview
Development of audio processing capabilities for the Edge AI board using TAS2563 audio codecs with dual microphone support for speech-to-text and text-to-speech applications.

## Hardware Specifications
- **Platform**: NXP i.MX8MM (Cortex-A53 quad-core)
- **Board Type**: imx8mm-jaguar-sentai
- **Audio Codec**: TAS2563 dual-chip configuration
- **Wireless**: NXP IW612 (WiFi 6 + Bluetooth 5.4 + 802.15.4)
- **Sensors**: BGT60TR13C radar, LIS2DH12 accelerometer, SHT40 temp/humidity
- **Power**: STUSB4500 USB-C PD controller

## Audio System Implementation

### TAS2563 Dual Audio Codec
**Implementation Status**: ✅ Complete (feature/sentai-tas2563-audio branch)

#### Hardware Configuration
- **TAS2563 Chip 1**: I2C address 0x4C (microphone input)
- **TAS2563 Chip 2**: I2C address 0x4D (microphone input)  
- **SAI Interface**: 30030000.sai (I2S audio interface)
- **Stereo Capture**: Dual microphone input for audio processing

#### Device Tree Configuration
**File**: `recipes-bsp/device-tree/lmp-device-tree/imx8mm-jaguar-sentai.dts`

```dts
&i2c2 {
    tas2563_1: tas2563@4c {
        compatible = "ti,tas2563";
        reg = <0x4c>;
        ti,chip-id = <0>;
        ti,imon-slot-no = <0>;
        ti,vmon-slot-no = <2>;
    };

    tas2563_2: tas2563@4d {
        compatible = "ti,tas2563";
        reg = <0x4d>;
        ti,chip-id = <1>;
        ti,imon-slot-no = <1>;
        ti,vmon-slot-no = <3>;
    };
};
```

#### ALSA Configuration
**File**: `recipes-bsp/alsa-state/alsa-state/imx8mm-jaguar-sentai/asound.conf`

Key features:
- **Stereo microphone capture** with TAS2563 devices
- **Hardware device mapping** for container applications
- **48kHz/16-bit** audio format support
- **Dual channel routing** for advanced audio processing

### Audio Software Stack

#### Driver Loading
**File**: `recipes-multimedia/alsa/alsa-utils/imx8mm-jaguar-sentai/load-audio-drivers.sh`

```bash
# Load TAS2563 kernel module
modprobe snd_soc_tas2563

# Initialize audio system
systemctl restart alsa-state
```

#### PulseAudio Integration
- **System-wide configuration** for container compatibility
- **Unix socket interface** at `/tmp/pulseaudio.socket`
- **Docker volume mounting** for audio access
- **Authentication bypass** for embedded use

### Testing & Validation

#### Audio Testing Scripts
- **detect-audio-hardware.sh** - Hardware detection and validation
- **test-tas2563-mics.sh** - Microphone capture testing
- **Audio playback testing** - Verify TAS2563 output capabilities

#### Container Audio Configuration
```yaml
# docker-compose.yml example
services:
  audio-app:
    devices:
      - /dev/snd:/dev/snd
    environment:
      - PULSE_SERVER=unix:/tmp/pulseaudio.socket
    volumes:
      - "/tmp:/tmp"
      - "/run/dbus/system_bus_socket:/run/dbus/system_bus_socket"
```

## Wireless Connectivity

### NXP IW612 Configuration
- **WiFi 6 (802.11ax)** - High-throughput networking
- **Bluetooth 5.4** - Device connectivity and pairing
- **802.15.4 / ZigBee** - IoT mesh networking (optional)
- **Concurrent operation** - All radios simultaneously active

### NetworkManager Integration
- **Dynamic connection management** 
- **Cellular modem support** (Quectel modules)
- **WiFi hotspot capabilities** via uap0 interface

## Sensor Integration

### Radar Sensor (BGT60TR13C)
- **Infineon SPI interface** - Custom driver integration
- **Presence detection** - Motion and occupancy sensing
- **Data logging** - Continuous monitoring capabilities

### Environmental Sensors
- **Temperature/Humidity** (SHT40) - I2C interface with lm-sensors
- **Accelerometer** (LIS2DH12) - IIO subsystem integration
- **Temperature** (STTS22H) - Additional precision temperature

## Development Workflow

### Build Configuration
```bash
# Set machine type
export MACHINE=imx8mm-jaguar-sentai

# Build with audio features
kas build kas/lmp-dynamicdevices.yml
```

### Testing Procedures

#### Audio Validation
```bash
# Test TAS2563 microphone capture
arecord -Dhw:0,0 -f S16_LE -r 48000 -c 2 test.wav

# Test with PulseAudio
parecord --device=tas2563-stereo test.wav
paplay test.wav
```

#### Sensor Testing
```bash
# Check radar sensor
seamless_dev_spi spi.mode=landscape rec.file=test.dat

# Monitor environmental sensors
sensors
watch -n 1 "cat /sys/bus/iio/devices/iio:device*/in_*_raw"
```

## Related Documentation

- **[Main Context](../context/MAIN_CONTEXT.md)** - Repository overview
- **[Wiki: Edge AI Board](../../wiki/Edge-AI-Board.md)** - User documentation
- **[TAS2563 Technical Context](./tas2563-technical-context.md)** - Detailed audio implementation (if exists)