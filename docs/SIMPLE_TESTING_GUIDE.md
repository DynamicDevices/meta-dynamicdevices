# Simple TAS2563 Echo Cancellation Testing Guide

## Quick Start: Regbin-Only Testing

### Why Start Simple?
- **No DSP firmware complexity** - just hardware configuration
- **Verify TDM slot setup** - confirm your device tree works
- **Hardware echo reference** - Profile 8 provides clean audio copy in slot 3
- **Software AEC ready** - use captured echo reference for AEC algorithms

### Prerequisites
```bash
# 1. Ensure regbin firmware is available
ls /lib/firmware/tas2563-1amp-reg.bin
# If missing, copy from driver package

# 2. Check audio card is detected
cat /proc/asound/cards
# Should show: tas2563audio

# 3. Verify controls are available
amixer -c tas2563audio contents | grep -E "Program|Profile"
```

## Step-by-Step Testing

### Step 1: Configure for Simple Mode
```bash
# Set bypass mode (regbin only, no DSP)
amixer -c tas2563audio cset name="Program" 1

# Select Profile 8 (echo cancellation hardware setup)  
amixer -c tas2563audio cset name="TASDEVICE Profile id" 8

# Verify settings
amixer -c tas2563audio cget name="Program"
amixer -c tas2563audio cget name="TASDEVICE Profile id"
```

### Step 2: Test Basic Audio Output
```bash
# Generate test tone
speaker-test -D hw:tas2563audio,0 -c 2 -r 48000 -f S32_LE -t sine -l 1

# Or play a WAV file
aplay -D hw:tas2563audio,0 -f S32_LE -r 48000 -c 2 /usr/share/sounds/alsa/Front_Left.wav
```

**Expected Result**: Audio should play from speakers (TDM slots 0,1)

### Step 3: Test 4-Channel Capture
```bash
# Capture all 4 channels for 5 seconds
arecord -D hw:tas2563audio,0 -f S32_LE -r 48000 -c 4 -d 5 multichannel_test.wav

# Check file properties
soxi multichannel_test.wav
# Should show: 4 channels, 48000 Hz, 32-bit
```

**Expected Result**: 4-channel file captured successfully

### Step 4: Verify Echo Reference
```bash
# Play audio while capturing (simultaneous)
aplay -D hw:tas2563audio,0 -f S32_LE -r 48000 -c 2 test_audio.wav &
PLAY_PID=$!

sleep 1  # Let playback start

arecord -D hw:tas2563audio,0 -f S32_LE -r 48000 -c 4 -d 10 echo_test.wav &
REC_PID=$!

# Wait for both to complete
wait $PLAY_PID $REC_PID

# Extract echo reference (channel 4 = slot 3)
sox echo_test.wav echo_reference.wav remix 4

# Listen to echo reference - should sound like played audio
play echo_reference.wav
```

**Expected Result**: Echo reference contains clean copy of played audio

### Step 5: Analyze Channel Content
```bash
# Split captured channels
sox echo_test.wav mic_left.wav remix 1      # PDM mic left
sox echo_test.wav mic_right.wav remix 2     # PDM mic right
sox echo_test.wav iv_monitor.wav remix 3    # I/V monitoring
sox echo_test.wav echo_ref.wav remix 4      # Echo reference

# Check each channel has content
for file in mic_left.wav mic_right.wav iv_monitor.wav echo_ref.wav; do
    echo "=== $file ==="
    sox $file -n stat 2>&1 | grep "RMS.*amplitude"
done
```

**Expected Results**:
- `mic_left.wav`, `mic_right.wav`: Should have microphone audio (if PDM mics connected)
- `iv_monitor.wav`: Should have low-level monitoring data
- `echo_ref.wav`: Should match played audio content

## Troubleshooting

### No Audio Output
```bash
# Check mixer settings
amixer -c tas2563audio contents

# Check for errors
dmesg | grep -i tas2563 | tail -10

# Verify SAI3 is active
cat /proc/asound/card0/pcm0p/sub0/hw_params
```

### No Capture Data
```bash
# Check capture device
arecord -l | grep tas2563

# Test with different format
arecord -D hw:tas2563audio,0 -f S16_LE -r 48000 -c 2 -d 2 test16.wav

# Check device tree configuration
cat /proc/device-tree/sound-tas2563/simple-audio-card,name
```

### Echo Reference Empty
```bash
# Verify simultaneous playback/capture works
aplay -D hw:tas2563audio,0 test.wav &
arecord -D hw:tas2563audio,0 -c 4 -d 5 capture.wav &
wait

# Check if Profile 8 is active
amixer -c tas2563audio cget name="TASDEVICE Profile id"
# Should return: values=8
```

## Advanced Testing: Software AEC

Once basic functionality works, test software echo cancellation:

### Simple AEC Test
```bash
# Record with echo present
aplay -D hw:tas2563audio,0 -f S32_LE -r 48000 -c 2 speech.wav &
arecord -D hw:tas2563audio,0 -f S32_LE -r 48000 -c 4 -d 10 aec_input.wav &
wait

# Extract signals for AEC
sox aec_input.wav near_end.wav remix 1,2    # Microphones (with echo)
sox aec_input.wav far_end.wav remix 4       # Echo reference (clean)

# Apply software AEC (example with SoX)
# This is a simple example - use proper AEC library for real applications
sox -m near_end.wav far_end.wav -t wav - | \
sox - aec_output.wav highpass 100 lowpass 8000

# Compare before/after
play near_end.wav    # Original with echo
play aec_output.wav  # After processing
```

## Next Steps

### When Basic Testing Works:
1. ✅ **Verify TDM slot assignments** are correct
2. ✅ **Confirm echo reference quality** matches playback
3. ✅ **Test microphone capture** (if PDM mics connected)
4. ✅ **Implement software AEC** using captured echo reference

### To Enable DSP Mode (Advanced):
```bash
# Switch to DSP mode (requires DSP firmware)
amixer -c tas2563audio cset name="Program" 0
amixer -c tas2563audio cset name="TASDEVICE Profile id" 8
amixer -c tas2563audio cset name="Configuration" 0
```

### Integration with Applications:
```bash
# Use ALSA configuration for application access
arecord -D eref -f S32_LE -r 48000 -c 1 echo_reference.wav
arecord -D tas2563_mic -f S32_LE -r 48000 -c 4 microphones.wav
```

## Success Criteria

✅ **Audio playback works** (stereo output)  
✅ **4-channel capture works** (mics + monitoring + echo ref)  
✅ **Echo reference contains played audio** (slot 3 working)  
✅ **Timing is synchronized** (no drift between playback/capture)  
✅ **Software AEC can use echo reference** (basic echo cancellation)

**Once these work, your TAS2563 Profile 8 echo cancellation setup is functioning correctly at the hardware level.**
