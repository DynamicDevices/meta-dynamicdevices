# TAS2563 Project Reference Documentation

## Overview
This document contains reference materials for the TAS2563 codec integration project.

## Datasheets and Specifications

### TAS2563 6.1W Boosted Class-D Audio Amplifier
- **File**: `docs/datasheets/TAS2563_datasheet.pdf`
- **Source**: [Texas Instruments TAS2563 Product Page](https://www.ti.com/lit/ds/symlink/tas2563.pdf)
- **Downloaded**: 2025-09-12
- **Description**: Official TI datasheet for the TAS2563 6.1W Boosted Class-D Audio Amplifier with Integrated DSP and IV Sense

### i.MX8MM Applications Processor Reference Manual
- **File**: `docs/datasheets/IMX8MMRM.pdf`
- **Document Code**: IMX8MMRM Rev 3
- **Revision**: Rev 3 (Jan 15, 2021)
- **Size**: 50.86 MB (Official version)
- **Description**: Official NXP reference manual for i.MX8MM Applications Processor
- **Key Section**: Chapter 13.10 - Synchronous Audio Interface (SAI)
- **SAI3 Base Address**: 0x3003_0000

### Key Specifications
- **Audio Interface**: I²S/TDM: 8 Channels of 32 Bit up to 96KSPS
- **Sample Rates**: 8 kHz to 96 kHz
- **DSP Features**: 
  - 10-Band Equalizer
  - 3-Band Dynamic EQ
  - Dynamic Range Compression
  - Psychoacoustic Bass
- **PDM Inputs**: 2 PDM Microphone inputs
- **Protection**: Real-Time I/V-Sense Speaker Protection

## Related Driver Code
- **Location**: `/data_drive/sentai/tas2781-linux-driver/`
- **Driver**: TAS2781 Linux driver (compatible with TAS2563)
- **Configuration**: Profile Mode 8 for echo cancellation

## Device Tree Configuration
- **Board**: i.MX8MM Jaguar Sentai
- **DTS File**: `meta-dynamicdevices-bsp/recipes-bsp/device-tree/lmp-device-tree/imx8mm-jaguar-sentai.dts`
- **Audio Interface**: SAI3 configured for TDM with 4 slots, 32-bit width

## Key Findings

### TDM Slot Configuration (from official datasheet)
- **Slot Length**: Configurable as 16-bit, 24-bit, or 32-bit slots
- **Word Length**: Configurable as 16-bit, 20-bit, 24-bit, or 32-bit words  
- **Profile 8**: Uses 16-bit audio data in 32-bit TDM slots
- **Register 0x16**: Controls boost current limiter (NOT slot configuration)
- **Slot Config Registers**: 0x06-0x10 (TDM_CFG0 through TDM_CFG10)

### Profile 8 Slot Assignment
- **Slot 0**: Left audio input (16-bit)
- **Slot 1**: Right audio input (16-bit)
- **Slot 2**: I/V sense feedback (16-bit)
- **Slot 3**: Echo reference for AEC (16-bit)

## Additional Documentation
- **TAS2563 Slot Analysis**: `docs/TAS2563_SLOT_CONFIGURATION.md`
- **TAS2563 Profile 8 Config**: `docs/TAS2563_PROFILE_8_CONFIGURATION.md`
- **i.MX8MM SAI3 Official Analysis**: `docs/IMX8MM_SAI3_OFFICIAL_ANALYSIS.md`

## Notes
- TAS2563 and TAS2781 share the same Linux driver
- Profile 8 configuration enables echo cancellation functionality
- Supports simultaneous playback, microphone capture, and echo reference
- All data uses 16-bit words in 32-bit TDM slots for proper timing
