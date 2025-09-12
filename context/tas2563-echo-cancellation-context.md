# TAS2563 Echo Cancellation Project Context

## Project Overview
Working with TAS2563 codec on i.MX8MM Jaguar Sentai board for echo cancellation functionality. Using TAS2781 Linux driver with Profile Mode 8 configuration for simultaneous audio playback, microphone capture, and echo reference generation.

## Current Status: ✅ AUDIO WORKING! BREAKTHROUGH ACHIEVED!
- **Hardware**: i.MX8MM SAI3 ↔ TAS2563 codec via I2S/TDM ✅ WORKING
- **Profile**: Mode 0 (Echo cancellation profile in simplified regbin firmware) ✅ WORKING  
- **Playback**: 2-channel stereo mode required (mono doesn't work) ✅ CONFIRMED
- **Capture**: 4-channel capture working (mics + echo reference) ✅ CONFIRMED
- **Firmware**: Regbin-only mode with single-profile firmware ✅ STABLE

## Key Technical Configuration

### TDM Slot Assignment (Profile 8)
| Slot | Direction | Data Size | Content | Usage |
|------|-----------|-----------|---------|-------|
| **Slot 0** | RX (to codec) | 16-bit | Left Audio | Speaker playback |
| **Slot 1** | RX (to codec) | 16-bit | Right Audio | Speaker playback |
| **Slot 2** | TX (from codec) | 16-bit | I/V Monitor | Speaker protection |
| **Slot 3** | TX (from codec) | 16-bit | Echo Reference | AEC processing |

### Device Tree Configuration (Verified Correct)
```dts
// File: meta-dynamicdevices-bsp/recipes-bsp/device-tree/lmp-device-tree/imx8mm-jaguar-sentai.dts

&sai3 {
    assigned-clocks = <&clk IMX8MM_CLK_SAI3>;
    assigned-clock-parents = <&clk IMX8MM_AUDIO_PLL1_OUT>;
    assigned-clock-rates = <12288000>;
    fsl,sai-mclk-direction-output;
    fsl,sai-synchronous-rx;
    dai-tdm-slot-num = <4>;
    dai-tdm-slot-width = <32>;
};

tas2563: tas2563@4C {
    compatible = "ti,tas2563";
    ti,left-slot = <0>;
    ti,right-slot = <1>;
    ti,imon-slot-no = <2>;
    ti,vmon-slot-no = <2>;
    ti,echo-ref = <3>;
    ti,i2s-bits = <32>;
    ti,mic-mode = <1>;
    ti,mic-left-edge = <0>;
    ti,mic-right-edge = <1>;
};
```

### Clock Configuration (Optimal)
- **MCLK**: 12.288 MHz (256 × 48kHz)
- **BCLK**: 6.144 MHz (128 × 48kHz) 
- **FSYNC**: 48 kHz
- **Frame**: 128-bit (4 × 32-bit slots)

## Firmware Architecture Understanding

### Regbin Firmware (Required)
- **File**: `tas2563-1amp-reg.bin` (from `tas2781-1amp-reg.json`)
- **Purpose**: Hardware configuration, register settings, TDM slot assignments
- **Profile 8**: Enables echo reference in slot 3 without DSP complexity
- **Location**: `/lib/firmware/`

### DSP Firmware (Optional - No Built-in AEC)
- **File**: `tas2563-1amp-dsp.bin` (from PPC3 tool)
- **Purpose**: Advanced audio processing and speaker protection (NOT AEC algorithms)
- **DSP Features** (verified from TAS2563 datasheet):
  - Smart Amp speaker protection algorithms
  - 10-Band Equalizer + 3-Band Dynamic EQ
  - Dynamic Range Compression
  - Psychoacoustic Bass Enhancement (PBE)
  - Smart Bass processing
  - Automatic Gain Control (AGC)
  - Ultrasound processing (up to 40kHz)
  - Real-time I/V monitoring for speaker protection
  - Thermal & over-excursion protection
  - Battery-tracking peak voltage limiter
  - Look-ahead Class-H boost optimization
- **CRITICAL**: TAS2563 DSP does NOT include acoustic echo cancellation algorithms
- **AEC Implementation**: Must be done in host processor software using echo reference from slot 3

### ALSA Control Structure
```bash
# Key controls for testing:
amixer -c tas2563audio cset name="Program" 1        # Bypass mode (regbin only)
amixer -c tas2563audio cset name="TASDEVICE Profile id" 8  # Echo cancellation profile
# For DSP mode: Program=0, Configuration=0
```

## Documentation Created
- `docs/REGBIN_VS_DSP_FIRMWARE.md` - Firmware types and testing strategy
- `docs/SIMPLE_TESTING_GUIDE.md` - Step-by-step testing procedures
- `docs/TAS2563_PROFILE_8_CONFIGURATION.md` - Complete Profile 8 analysis
- `docs/TAS2563_SLOT_CONFIGURATION.md` - Corrected slot configuration details
- `docs/IMX8MM_SAI3_OFFICIAL_ANALYSIS.md` - NXP side verification
- `docs/IMX8MM_TDM_MODE_SUPPORT.md` - TDM capabilities explanation
- `docs/SIGNAL_TO_SLOT_MAPPING.md` - Hardware to software signal flow
- `docs/REFERENCE_DOCUMENTATION.md` - Datasheets and specifications

## Reference Documentation
- **TAS2563 Datasheet**: `docs/datasheets/TAS2563_datasheet.pdf`
- **i.MX8MM Reference Manual**: `docs/datasheets/IMX8MMRM.pdf` (Official Rev 3)
- **Driver Source**: `/data_drive/sentai/tas2781-linux-driver/`
- **JSON Configuration**: `/data_drive/sentai/tas2781-linux-driver/regbin/jsn/tas2563-1amp-reg.json`

## Next Steps for Testing

### Immediate Testing (Regbin-Only Mode) - Primary AEC Approach
1. **Verify regbin firmware**: Ensure `tas2563-1amp-reg.bin` in `/lib/firmware/`
2. **Configure bypass mode**: `Program=1`, `Profile id=8`
3. **Test stereo playback**: Verify audio output (slots 0,1)
4. **Test 4-channel capture**: Verify mics + echo reference (slots 0,1,2,3)
5. **Verify echo reference**: Confirm slot 3 contains clean audio copy
6. **Software AEC implementation**: Develop host processor AEC algorithms using echo reference

### Advanced Testing (DSP Mode) - Audio Enhancement Only
1. **Add DSP firmware**: Copy `tas2563-1amp-dsp.bin` to `/lib/firmware/`
2. **Enable DSP mode**: `Program=0`, `Profile id=8`, `Configuration=0`
3. **Test enhanced features**: Smart amplifier protection, EQ, compression, bass enhancement
4. **Note**: AEC algorithms still implemented in host software, DSP provides audio quality improvements

## BREAKTHROUGH FINDINGS - September 12, 2025

### ✅ Audio System Working Successfully
1. **Regbin-Only Mode**: TAS2563 working perfectly without DSP firmware
2. **Simplified Firmware**: Single-profile regbin (`tas2563-echo-cancellation.bin`) eliminates conflicts
3. **Stereo Playback Required**: 2-channel mode works, 1-channel mono fails
4. **4-Channel Capture Working**: Successfully capturing mics + echo reference
5. **SAI3 Interface Verified**: Hardware path confirmed working with proper TDM signaling

### Critical Configuration Requirements
- **Playback**: Must use 2-channel stereo (`speaker-test -c 2`) even with single speaker
- **Capture**: 4-channel mode captures all TDM slots (mics in 0,1 + echo ref in slot 3)
- **Profile**: Use Profile 0 in simplified firmware (equivalent to original Profile 8)
- **Service**: `tas2563-init.service` auto-detects regbin-only mode and configures correctly

### Audio Files Captured for Analysis
- `/tmp/test_4ch_capture.wav`: 4-channel ambient capture (1.1MB, 3 seconds)
- `/tmp/echo_test_capture.wav`: Capture during playback attempt (1.9MB, 5 seconds)  
- `/tmp/post_playback_capture.wav`: Capture immediately after playback (750KB, 2 seconds)

## Key Findings & Corrections
- **Register 0x16**: Boost Current Limiter (NOT slot configuration as initially thought)
- **Slot Data Size**: All 4 slots use 16-bit data within 32-bit TDM slots
- **Echo Reference**: Hardware-generated in slot 3, synchronized with playback
- **i.MX8MM SAI3**: Fully compliant with NXP specifications, optimally configured
- **TDM Mode**: Provides tri-state control and dynamic slot masking for clean protocol
- **DSP Firmware Clarification**: TAS2563 DSP does NOT include AEC algorithms (verified from datasheet)
- **AEC Strategy**: Echo cancellation must be implemented in host processor software using hardware echo reference
- **DSP Benefits**: Audio enhancement, speaker protection, and power optimization (not AEC processing)

## Testing Commands Ready
```bash
# Basic functionality test
amixer -c tas2563audio cset name="Program" 1
amixer -c tas2563audio cset name="TASDEVICE Profile id" 8
aplay -D hw:tas2563audio,0 -f S32_LE -r 48000 -c 2 test.wav
arecord -D hw:tas2563audio,0 -f S32_LE -r 48000 -c 4 -d 5 capture.wav

# Echo reference extraction
sox capture.wav echo_reference.wav remix 4
play echo_reference.wav  # Should contain clean copy of played audio
```

## Current Working Directory
`/home/ajlennon/data_drive/dd/meta-dynamicdevices`

## Project Repository Structure
- **BSP Layer**: `meta-dynamicdevices-bsp/` - Board-specific configurations
- **Device Tree**: `meta-dynamicdevices-bsp/recipes-bsp/device-tree/lmp-device-tree/imx8mm-jaguar-sentai.dts`
- **ALSA Config**: `meta-dynamicdevices-bsp/recipes-bsp/alsa-state/alsa-state/imx8mm-jaguar-sentai/asound.conf`
- **Documentation**: `docs/` - Technical analysis and guides
- **Context**: `context/` - Project context files

## Ready for Implementation
The TAS2563 echo cancellation configuration is **theoretically complete and verified**. All hardware configurations have been analyzed against official specifications. The system is ready for practical testing starting with regbin-only mode for simplicity, then advancing to full DSP mode for enhanced features.

**Status**: Ready to begin hardware testing and validation of echo cancellation functionality.
