# TAS2563 Firmware Types: Regbin vs DSP Firmware

## Overview of TAS2563 Firmware Architecture

The TAS2563 codec uses **two separate firmware components** that serve different purposes:

### 1. **Regbin Firmware** (.bin file from .json)
**Purpose**: Hardware configuration and register settings
**File**: `tas2781-1amp-reg.bin` (generated from `tas2781-1amp-reg.json`)

**What it does:**
- **Register Configuration**: Sets up codec registers for I2S/TDM mode
- **Slot Assignment**: Configures which TDM slots are used for what signals
- **Hardware Setup**: Pin configurations, clock settings, power management
- **Profile Selection**: Different hardware configurations (Profile 0-12+)
- **Basic Audio Path**: Enables audio input/output without DSP processing

**Key Point**: **Regbin firmware is REQUIRED for basic audio functionality**

### 2. **DSP Firmware** (.bin file from PPC3 tool)
**Purpose**: Advanced audio processing algorithms
**File**: `tas2781-1amp-dsp.bin` (generated with PPC3 tool)

**What it does:**
- **Smart Amplifier**: Speaker protection algorithms
- **Dynamic Range Control**: Compression, limiting
- **EQ Processing**: Multi-band equalizers
- **Advanced Features**: Psychoacoustic bass, thermal protection
- **Echo Processing**: Advanced AEC algorithms (if included)

**Key Point**: **DSP firmware is OPTIONAL for basic echo cancellation testing**

## TAS2563 Control Structure

### ALSA Controls Hierarchy
```bash
# Check available controls
amixer -c tas2563audio contents

# Key controls:
"Program"              # 0=DSP mode, 1=Bypass mode
"TASDEVICE Profile id" # Regbin profile selection (0-12+)
"Configuration"        # DSP configuration (when Program=0)
```

### Control Relationships
```
Program = 1 (Bypass Mode):
├── Only regbin firmware used
├── No DSP processing
├── Basic audio input/output
└── "Configuration" control ignored

Program = 0 (DSP Mode):
├── Both regbin + DSP firmware required
├── Full DSP processing enabled
├── "Configuration" selects DSP algorithm
└── Advanced features available
```

## Profile 8 Echo Cancellation Analysis

### What Profile 8 Provides (Regbin Only)
Based on the JSON analysis, **Profile 8** (`08-I2S-16bit-echoref-slot0-LR-mixer-pwm0`) provides:

✅ **Hardware Configuration:**
- TDM slot assignments (slots 0,1,2,3)
- I2S interface setup (16-bit data, 32-bit slots)
- PDM microphone enable
- Echo reference routing to slot 3
- Bidirectional audio (simultaneous TX/RX)

✅ **Basic Echo Reference:**
- Clean copy of playback audio in RX slot 3
- Synchronized timing with microphone capture
- Hardware-level echo reference generation

❌ **What's Missing Without DSP:**
- Advanced AEC algorithms
- Noise reduction
- Dynamic processing
- Smart amplifier protection

## Testing Strategy: Start Simple

### Phase 1: Regbin-Only Testing (Recommended Start)

**Goal**: Verify basic echo cancellation setup without DSP complexity

**Configuration:**
```bash
# Set bypass mode (regbin only, no DSP)
amixer -c tas2563audio cset name="Program" 1

# Select Profile 8 (echo cancellation hardware setup)
amixer -c tas2563audio cset name="TASDEVICE Profile id" 8
```

**What you can test:**
1. **Stereo Playback**: Audio output to speakers (slots 0,1)
2. **4-Channel Capture**: Mics + echo reference (slots 0,1,2,3)
3. **Echo Reference**: Clean audio copy in channel 3
4. **Timing Synchronization**: Frame-aligned capture/playback
5. **Basic AEC**: Software-based echo cancellation using captured echo reference

### Phase 2: DSP Mode Testing (Advanced)

**Goal**: Enable full DSP processing for advanced features

**Configuration:**
```bash
# Set DSP mode (requires both regbin + DSP firmware)
amixer -c tas2563audio cset name="Program" 0

# Select Profile 8
amixer -c tas2563audio cset name="TASDEVICE Profile id" 8

# Select DSP configuration
amixer -c tas2563audio cset name="Configuration" 0
```

## Simple Testing Procedure

### Step 1: Verify Hardware Setup (Regbin Only)

```bash
# 1. Set bypass mode (no DSP required)
amixer -c tas2563audio cset name="Program" 1
amixer -c tas2563audio cset name="TASDEVICE Profile id" 8

# 2. Test stereo playback
aplay -D hw:tas2563audio,0 -f S32_LE -r 48000 -c 2 test_stereo.wav

# 3. Test 4-channel capture
arecord -D hw:tas2563audio,0 -f S32_LE -r 48000 -c 4 -d 10 test_capture.wav

# 4. Verify echo reference (should contain audio copy)
arecord -D eref -f S32_LE -r 48000 -c 1 -d 5 echo_ref_test.wav
```

### Step 2: Analyze Captured Data

```bash
# Check captured channels
sox test_capture.wav test_ch0.wav remix 1    # Left mic
sox test_capture.wav test_ch1.wav remix 2    # Right mic  
sox test_capture.wav test_ch2.wav remix 3    # I/V monitor
sox test_capture.wav test_ch3.wav remix 4    # Echo reference

# Verify echo reference contains audio
play echo_ref_test.wav  # Should hear playback audio
```

### Step 3: Basic Software AEC Test

```bash
# Simultaneous playback and capture for AEC testing
aplay -D hw:tas2563audio,0 -f S32_LE -r 48000 -c 2 tts_output.wav &
PLAY_PID=$!

arecord -D hw:tas2563audio,0 -f S32_LE -r 48000 -c 4 -d 10 aec_test.wav &
REC_PID=$!

# Wait for completion
wait $PLAY_PID $REC_PID

# Extract channels for AEC processing
sox aec_test.wav mic_left.wav remix 1
sox aec_test.wav mic_right.wav remix 2  
sox aec_test.wav echo_ref.wav remix 4

# Use software AEC (WebRTC, Speex, etc.)
# webrtc_aec --far echo_ref.wav --near mic_left.wav --out clean_left.wav
```

## Firmware File Locations

### Required Files for Testing

**Regbin Firmware (Required):**
```bash
# Copy regbin file to firmware directory
cp /data_drive/sentai/tas2781-linux-driver/regbin/toolset/parser/tas2563-1amp-reg.bin \
   /lib/firmware/

# Or use your custom Profile 8 regbin
cp your_profile8_regbin.bin /lib/firmware/tas2563-1amp-reg.bin
```

**DSP Firmware (Optional for Phase 1):**
```bash
# Only needed for Program=0 (DSP mode)
cp your_dsp_firmware.bin /lib/firmware/tas2563-1amp-dsp.bin
```

## Troubleshooting Common Issues

### Issue: No Audio Output
```bash
# Check regbin loading
dmesg | grep -i tas2563
cat /sys/kernel/debug/asoc/tas2563audio/dapm_pop_time

# Verify controls
amixer -c tas2563audio contents | grep -E "Program|Profile"
```

### Issue: No Echo Reference
```bash
# Verify 4-channel capture
arecord -D hw:tas2563audio,0 -f S32_LE -r 48000 -c 4 -d 1 test.wav
soxi test.wav  # Should show 4 channels

# Check if channel 3 has data
sox test.wav -n stat remix 4  # Should show non-zero RMS if echo ref working
```

### Issue: Timing Misalignment
```bash
# Verify frame synchronization
cat /proc/asound/card0/pcm0p/sub0/hw_params
cat /proc/asound/card0/pcm0c/sub0/hw_params
# Both should show same rate/format
```

## Recommendation: Start with Regbin-Only

**For initial testing, I recommend starting with regbin-only mode (Program=1) because:**

1. ✅ **Simpler Setup**: No DSP firmware complexity
2. ✅ **Hardware Verification**: Confirms TDM slot configuration works
3. ✅ **Echo Reference**: Profile 8 provides hardware echo reference in slot 3
4. ✅ **Basic AEC**: You can implement software AEC using the echo reference
5. ✅ **Debugging**: Easier to isolate hardware vs software issues
6. ✅ **Incremental**: Add DSP firmware later for advanced features

**The hardware-level echo reference from Profile 8 regbin is sufficient for basic echo cancellation testing and development.**

Once you verify the basic functionality works, you can then add DSP firmware for advanced processing features.

## Summary

- **Regbin Firmware**: Hardware configuration, slot assignments, basic audio paths (**Required**)
- **DSP Firmware**: Advanced audio processing algorithms (**Optional for basic testing**)
- **Profile 8**: Provides hardware echo reference in regbin-only mode
- **Testing Strategy**: Start with `Program=1` (bypass) + `Profile id=8` for simplicity
- **Echo Cancellation**: Hardware echo reference enables software-based AEC without DSP firmware
