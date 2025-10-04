# USB Audio Scripts

This directory contains USB audio gadget configuration and testing scripts for Dynamic Devices Edge boards.

## Scripts Overview

### Setup Scripts
- **`setup-fixed-uac2.sh`** - Configure USB Audio Class 2 gadget with fixed parameters
- **`setup-usb-mixed-audio-gadget`** - Mixed USB audio gadget configuration
- **`start-fixed-usb-audio.sh`** - Start USB audio gadget service

### Testing Scripts  
- **`uac2-module-test.sh`** - Test USB Audio Class 2 module functionality
- **`usb-audio-test.sh`** - Comprehensive USB audio testing suite

### Service Files
- **`usb-composite-gadget-fixed.service`** - Systemd service for USB audio gadget
- **`uac2-capture-fix-override.conf`** - Systemd override to fix UAC2 capture with `c_hs_bint=1`

## Usage

### Basic USB Audio Setup
```bash
# Configure and start USB audio gadget
./setup-fixed-uac2.sh
./start-fixed-usb-audio.sh

# Test functionality
./usb-audio-test.sh
```

### Testing Audio Paths
```bash
# Test bidirectional audio
./uac2-module-test.sh

# Verify host can record from target
arecord -D hw:Gadget,0 -f S16_LE -r 48000 test.wav

# Verify target can play host audio
aplay -D hw:Gadget,0 test_tone.wav
```

## Board Compatibility

- **Edge AI (imx8mm-jaguar-sentai)**: Full USB audio support
- **Edge EInk (imx93-jaguar-eink)**: Limited - primarily for debugging

## Integration

These scripts integrate with:
- **Container audio**: Routes through USB gadget for host communication
- **PulseAudio**: Bidirectional audio routing
- **GStreamer**: Audio pipeline integration (`loop_playback_far`, `loop_capture_near_rec`)

## Troubleshooting

See [USB-Audio-Integration](../../wiki/USB-Audio-Integration.md) in the wiki for detailed troubleshooting.
