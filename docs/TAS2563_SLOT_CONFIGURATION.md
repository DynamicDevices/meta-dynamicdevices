# TAS2563 Slot Configuration Analysis

## Official TAS2563 Datasheet Information

**Source**: [TAS2563 Datasheet](https://www.ti.com/lit/ds/symlink/tas2563.pdf) - Downloaded 2025-09-12

## TDM Slot Configuration Details

### Supported TDM Configurations
From the official datasheet (Section 7.4.3.1):

- **Up to 16 × 32-bit time slots** at 44.1/48 kHz
- **Up to 8 × 32-bit time slots** at 88.2/96 kHz  
- **Up to 4 × 32-bit time slots** at 176.4/192 kHz
- **2 time slots at 32 bits** width
- **4 or 8 time slots at 16, 24 or 32 bits** width

### TDM Slot Length Configuration (Register 0x08 - TDM_CFG2)

**RX_SLEN[1:0] - TDM RX Time Slot Length**:
- `00b` = **16-bit** slots
- `01b` = **24-bit** slots  
- `10b` = **32-bit** slots
- `11b` = Reserved

### TDM Word Length Configuration (Register 0x08 - TDM_CFG2)

**RX_WLEN[1:0] - TDM RX Sample Word Length**:
- `00b` = **16-bit** words
- `01b` = **20-bit** words
- `10b` = **24-bit** words
- `11b` = **32-bit** words

## Profile 8 Configuration Analysis

### Register 0x16 Clarification
**Register 0x16** in the TAS2563 is **NOT** for slot configuration. According to the datasheet:
- **Register 0x16** = `BIL_and_ICLA_CFG0` (Boost Current limiter and ICLA)
- **TDM slot configuration** uses registers **0x06-0x10** (TDM_CFG0 through TDM_CFG10)

### Actual Slot Configuration Registers

| Register | Name | Function |
|----------|------|----------|
| 0x08 | TDM_CFG2 | **Slot length and word length** |
| 0x09 | TDM_CFG3 | **RX Left/Right slot assignment** |
| 0x0B | TDM_CFG5 | **Voltage sense TX slot** |
| 0x0C | TDM_CFG6 | **Current sense TX slot** |
| 0x0D | TDM_CFG7 | **VBAT TX slot** |
| 0x0E | TDM_CFG8 | **Temperature TX slot** |
| 0x0F | TDM_CFG9 | **Limiter gain reduction TX slot** |
| 0x10 | TDM_CFG10 | **Boost sync TX slot** |

## Profile 8 Slot Usage

Based on the JSON configuration name "08-I2S-16bit-echoref-slot0-LR-mixer-pwm0":

### Likely Slot Assignment:
- **Slot 0**: Left audio input (RX)
- **Slot 1**: Right audio input (RX) 
- **Slot 2**: I/V sense feedback (TX) - Current/Voltage monitoring
- **Slot 3**: Echo reference (TX) - For acoustic echo cancellation

### Data Sizes:
- **Audio slots (0,1)**: 16-bit audio data
- **Feedback slots (2,3)**: 16-bit monitoring data
- **Slot width**: 32-bit (configured in device tree)

## Device Tree Configuration Match

Your current DTS configuration is correct:

```dts
// TDM configuration
dai-tdm-slot-num = <4>;        // 4 slots total
dai-tdm-slot-width = <32>;     // 32-bit slot width
ti,i2s-bits = <32>;           // 32-bit I2S format

// Slot assignments  
ti,left-slot = <0>;           // TX slot 0 - left audio
ti,right-slot = <1>;          // TX slot 1 - right audio  
ti,imon-slot-no = <2>;        // Current sense feedback
ti,vmon-slot-no = <2>;        // Voltage sense feedback
ti,echo-ref = <3>;            // Echo reference slot
```

## Correction to Previous Analysis

My previous interpretation of register 0x16 = 0x42 was **incorrect**. Register 0x16 is for boost current limiting, not slot configuration. The actual slot configuration comes from the regbin firmware and the device tree properties shown above.

The **16-bit audio data** is transmitted in **32-bit TDM slots**, providing proper timing alignment and allowing for additional monitoring data in the unused slot space.
