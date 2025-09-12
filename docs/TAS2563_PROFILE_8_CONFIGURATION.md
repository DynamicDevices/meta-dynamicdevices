# TAS2563 Profile Mode 8 Configuration

## Profile Overview
**Profile Name**: `08-I2S-16bit-echoref-slot0-LR-mixer-pwm0`  
**Purpose**: Echo cancellation mode with simultaneous playback, microphone capture, and echo reference

## Register Configuration

### Key Registers from JSON Configuration

| Register | Name | Value | Function |
|----------|------|-------|----------|
| 0x0A | TDM_CFG4 | 0x3A | TDM TX configuration |
| 0x0D | TDM_CFG7 | 0x01 | VBAT configuration |
| 0x10 | TDM_CFG10 | 0x04 | Boost sync configuration |
| 0x16 | BIL_and_ICLA_CFG0 | 0x42 | Boost current limiter |

### Detailed Register Analysis

#### Register 0x0A (TDM_CFG4) = 0x3A
**TDM TX Configuration Register**

```
Binary: 0b00111010

Bit 7 (TX_KEEPER_LSB): 0 = Full-cycle LSB drive
Bit 6 (TX_KEEPER_ALWAYS): 0 = 1 LSB cycle bus keeper  
Bit 5 (TX_KEEPER_EN): 1 = Bus keeper Enabled
Bit 4 (TX_FILL): 1 = Unused bits Hi-Z
Bits 3-1 (TX_OFFSET): 5 = TX offset 5 SBCLK cycles
Bit 0 (TX_EDGE): 0 = TX on Rising edge
```

**Key Settings**:
- **TX Offset**: 5 SBCLK cycles from frame start
- **Bus Keeper**: Enabled for clean TX signals
- **Unused Bits**: Hi-Z (high impedance)
- **TX Edge**: Rising edge of SBCLK

#### Register 0x16 (BIL_and_ICLA_CFG0) = 0x42
**Boost Current Limiter Configuration** (NOT slot configuration)

This register controls boost converter current limiting and ICLA (Inter-Chip Load Alignment), not TDM slot assignments.

## TDM Slot Configuration

### 4-Slot TDM Frame Layout

| Slot | Direction | Data Type | Bit Width | Content |
|------|-----------|-----------|-----------|---------|
| **0** | RX (to codec) | Audio | 16-bit | Left channel audio input |
| **1** | RX (to codec) | Audio | 16-bit | Right channel audio input |
| **2** | TX (from codec) | Monitoring | 16-bit | I/V sense feedback |
| **3** | TX (from codec) | Reference | 16-bit | Echo reference for AEC |

### TDM Frame Timing

```
Frame Structure (128-bit total):
┌─────────┬─────────┬─────────┬─────────┐
│ Slot 0  │ Slot 1  │ Slot 2  │ Slot 3  │
│ 32-bit  │ 32-bit  │ 32-bit  │ 32-bit  │
│ L Audio │ R Audio │ I/V Mon │ Echo Ref│
└─────────┴─────────┴─────────┴─────────┘

Data Format per Slot:
┌─────────────────┬───────────────────┐
│ 16-bit Audio    │ 16-bit Padding    │
│ (Left Justified)│ (Unused/Hi-Z)     │
└─────────────────┴───────────────────┘
```

### Clock Configuration
- **Sample Rate**: 48 kHz
- **Slot Width**: 32 bits
- **Frame Size**: 4 × 32 = 128 bits
- **BCLK Frequency**: 128 × 48 kHz = **6.144 MHz**
- **FSYNC Frequency**: 48 kHz

## Device Tree Mapping

Your current DTS configuration correctly maps to Profile 8:

```dts
sound-tas2563 {
    compatible = "simple-audio-card";
    simple-audio-card,format = "i2s";
    
    cpudai2: simple-audio-card,cpu {
        sound-dai = <&sai3>;
        dai-tdm-slot-num = <4>;        // 4 TDM slots
        dai-tdm-slot-width = <32>;     // 32-bit slot width
    };
    
    simple-audio-card,codec {
        sound-dai = <&tas2563>;
    };
};

tas2563: tas2563@4C {
    compatible = "ti,tas2563";
    
    // Slot assignments for Profile 8
    ti,left-slot = <0>;           // Slot 0: Left audio
    ti,right-slot = <1>;          // Slot 1: Right audio
    ti,imon-slot-no = <2>;        // Slot 2: Current sense
    ti,vmon-slot-no = <2>;        // Slot 2: Voltage sense (combined)
    ti,echo-ref = <3>;            // Slot 3: Echo reference
    ti,i2s-bits = <32>;          // 32-bit I2S format
};
```

## SAI3 Configuration

```dts
&sai3 {
    assigned-clocks = <&clk IMX8MM_CLK_SAI3>;
    assigned-clock-parents = <&clk IMX8MM_AUDIO_PLL1_OUT>;
    assigned-clock-rates = <12288000>;        // MCLK = 256 × 48kHz
    fsl,sai-mclk-direction-output;
    fsl,sai-synchronous-rx;                   // RX uses TX clocks
    status = "okay";
};
```

## Echo Cancellation Operation

### Signal Flow
1. **Audio Playback**: Host → SAI3 → Slots 0,1 → TAS2563 → Speaker
2. **Microphone Capture**: PDM Mics → TAS2563 DSP → Processing
3. **Echo Reference**: TAS2563 → Slot 3 → SAI3 → Host
4. **I/V Monitoring**: TAS2563 → Slot 2 → SAI3 → Host (optional)

### AEC Processing
- **Echo Reference**: Clean copy of audio sent to speaker
- **Microphone Signal**: Captured audio with echo + desired signal  
- **AEC Algorithm**: Uses echo reference to remove echo from microphone
- **Output**: Clean microphone signal with echo removed

## Key Features of Profile 8
- ✅ **Simultaneous bidirectional audio**
- ✅ **Real-time echo cancellation**
- ✅ **I/V sense monitoring for speaker protection**
- ✅ **16-bit audio quality with 32-bit slot alignment**
- ✅ **Low latency DSP processing**
- ✅ **PDM microphone support**

## Verification Commands

```bash
# Check TDM slot configuration
cat /proc/asound/card0/pcm0p/sub0/hw_params
cat /proc/asound/card0/pcm0c/sub0/hw_params

# Test playback and capture simultaneously  
aplay -D hw:0,0 test.wav &
arecord -D hw:0,0 -f S16_LE -r 48000 -c 2 echo_test.wav

# Monitor I2C register values
i2cget -y 1 0x4C 0x0A  # Should read 0x3A
i2cget -y 1 0x4C 0x10  # Should read 0x04
```

This configuration enables full echo cancellation functionality with the TAS2563 codec on your i.MX8MM Jaguar Sentai board.
