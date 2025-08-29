# Edge AI Board Context

**GitHub**: [Edge AI Milestone](https://github.com/DynamicDevices/meta-dynamicdevices/milestone/1)

## Hardware
- **SoC**: i.MX8MM (Cortex-A53), **Audio**: TAS2563 dual-chip
- **Wireless**: IW612 (WiFi 6, BT 5.4, 802.15.4)
- **Sensors**: BGT60TR13C radar, LIS2DH12, SHT40, **Power**: STUSB4500

## TAS2563 Audio ✅
- **Config**: Dual-chip (0x4C/0x4D), SAI interface, stereo capture
- **Driver**: Android TAS2563 with firmware support
- **Files**: `lmp-device-tree/imx8mm-jaguar-sentai.dts`, kernel configs
## Audio Stack ✅
- **Driver**: Android TAS2563 with firmware support (`tas2563_uCDSP.bin`)
- **ALSA**: Stereo capture, 48kHz/16-bit, container support
- **PulseAudio**: System-wide, Unix socket, Docker integration
- **Testing**: `detect-audio-hardware.sh`, `test-tas2563-mics.sh`

## Wireless ✅
- **IW612**: WiFi 6, BT 5.4, 802.15.4 concurrent operation
- **NetworkManager**: Dynamic connections, cellular, hotspot

## Sensors ✅
- **Radar**: BGT60TR13C (SPI, presence detection)
- **Environmental**: SHT40 (temp/humidity), LIS2DH12 (accel), STTS22H

## Build & Test
```bash
export MACHINE=imx8mm-jaguar-sentai
kas build kas/lmp-dynamicdevices.yml

# Audio test
arecord -Dhw:0,0 -f S16_LE -r 48000 -c 2 test.wav

# Sensor test  
sensors
```

## Documentation
- **Main**: `docs/context/MAIN_CONTEXT.md`
- **Wiki**: `wiki/Edge-AI-Board.md`