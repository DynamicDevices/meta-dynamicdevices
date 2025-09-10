# TAS2563 Echo Cancellation Testing Checklist

## Pre-Build Verification ✅
- [x] TAS2781 upstream driver configured with patches
- [x] Profile 8 regbin analysis completed  
- [x] Device tree bidirectional SAI3 configured
- [x] ALSA echo reference PCMs configured
- [x] tas2563-init script installed
- [x] Context optimized and committed
- [x] Repository cleaned up

## Build Testing
- [ ] Build completes without errors: `kas build kas/lmp-dynamicdevices.yml`
- [ ] TAS2781 kernel module builds successfully
- [ ] Device tree compiles without warnings
- [ ] ALSA configuration files installed correctly
- [ ] tas2563-init script installed to /usr/bin/

## Hardware Testing
- [ ] Audio card detected: `cat /proc/asound/cards` shows "Audio"
- [ ] TAS2563 driver loads: `dmesg | grep -i tas` shows successful init
- [ ] Profile 8 available: `amixer -c Audio controls | grep Profile`
- [ ] Echo reference initialization: `tas2563-init echo-removal`
- [ ] Profile verification: `amixer -c Audio cget name="TASDEVICE Profile id"` = 8

## Echo Reference Testing
- [ ] Capture devices available: `arecord -l | grep Audio`
- [ ] Direct hardware capture: `arecord -D hw:Audio,0,1 -f S32_LE -r 48000 -c 1 -d 5 test.wav`
- [ ] ALSA alias capture: `arecord -D eref -f S32_LE -r 48000 -c 1 -d 5 test.wav`
- [ ] Legacy format: `arecord -D eref_16bit -f S16_LE -r 48000 -c 1 -d 5 test.wav`
- [ ] Audio playback: `aplay -D hw:Audio,0,0 test_audio.wav`

## Functional Testing
- [ ] Speaker output works (slots 0-1)
- [ ] Echo reference captures speaker output (slot 3)
- [ ] Multiple capture readers work (dsnoop)
- [ ] Profile switching: `tas2563-init music`, `tas2563-init bypass`
- [ ] Status reporting: `tas2563-init status`

## Integration Testing
- [ ] AEC pipeline can access echo reference
- [ ] Microphone input still works (micfil)
- [ ] No audio dropouts or glitches
- [ ] Performance acceptable for real-time AEC

## Troubleshooting Commands
```bash
# Check audio cards
cat /proc/asound/cards
cat /proc/asound/pcm

# Check TAS2563 driver
dmesg | grep -i tas
lsmod | grep tas

# Check ALSA controls
amixer -c Audio controls | grep -i "tas\|profile\|program"
amixer -c Audio cget name="TASDEVICE Profile id"

# Test capture devices
arecord -l
arecord -D hw:Audio,0,1 -f S32_LE -r 48000 -c 1 -d 1 /dev/null

# Profile management
tas2563-init status
tas2563-init echo-removal
```

## Expected Results
- **Driver**: TAS2781 driver loads successfully, no IRQ errors
- **Profile**: Profile 8 active by default (echo removal mode)
- **Audio**: Speaker playback works, echo reference captures speaker output
- **Format**: Native S32_LE @ 48kHz, legacy S16_LE conversion available
- **Performance**: Real-time capture without dropouts
