# Signal-to-Slot Mapping and Linux Audio Subsystem Integration

## Physical Signal to TDM Slot Mapping

### Device Tree Configuration Analysis

Your device tree explicitly defines how physical signals map to TDM slots:

```dts
tas2563: tas2563@4C {
    // TDM Slot Assignments (Profile 8)
    ti,left-slot = <0>;           /* TX slot 0 - left audio output */
    ti,right-slot = <1>;          /* TX slot 1 - right audio output */
    ti,imon-slot-no = <2>;        /* Current sense feedback */
    ti,vmon-slot-no = <2>;        /* Voltage sense feedback - combined */
    ti,echo-ref = <3>;            /* Echo reference output slot for AEC */
    
    // PDM Microphone Configuration
    ti,mic-mode = <1>;            /* Enable PDM microphone capture */
    ti,mic-bias-enable = <1>;     /* Enable microphone bias */
    ti,pdm-edge = <3>;            /* Both rising and falling edge for dual mics */
    ti,mic-left-edge = <0>;       /* Left mic on rising edge */
    ti,mic-right-edge = <1>;      /* Right mic on falling edge */
};
```

### Physical Signal Flow

#### **TX Direction (i.MX8MM → TAS2563)**
```
SAI3_TXD (Physical Wire) carries TDM frame:
┌─────────┬─────────┬─────────┬─────────┐
│ Slot 0  │ Slot 1  │ Slot 2  │ Slot 3  │
│ 32-bit  │ 32-bit  │ 32-bit  │ 32-bit  │
└─────────┴─────────┴─────────┴─────────┘
     │         │         │         │
     │         │         │         └─ Not used in TX
     │         │         └─────────── Not used in TX  
     │         └───────────────────── Right Audio → Speaker
     └─────────────────────────────── Left Audio → Speaker
```

#### **RX Direction (TAS2563 → i.MX8MM)**
```
SAI3_RXD (Physical Wire) carries TDM frame:
┌─────────┬─────────┬─────────┬─────────┐
│ Slot 0  │ Slot 1  │ Slot 2  │ Slot 3  │
│ 32-bit  │ 32-bit  │ 32-bit  │ 32-bit  │
└─────────┴─────────┴─────────┴─────────┘
     │         │         │         │
     │         │         │         └─ Echo Reference (clean audio copy)
     │         │         └─────────── I/V Monitor (current/voltage sense)
     │         └───────────────────── PDM Mic Right
     └─────────────────────────────── PDM Mic Left
```

## Linux Audio Subsystem Integration

### ALSA PCM Device Creation

The `simple-audio-card` driver creates ALSA PCM devices based on your configuration:

```dts
sound-tas2563 {
    compatible = "simple-audio-card";
    simple-audio-card,name = "tas2563-audio";
    
    cpudai2: simple-audio-card,cpu {
        sound-dai = <&sai3>;
        dai-tdm-slot-num = <4>;        /* 4 TDM slots */
        dai-tdm-slot-width = <32>;     /* 32-bit slots */
    };
    
    simple-audio-card,codec {
        sound-dai = <&tas2563>;
    };
};
```

**Result**: Creates `/dev/snd/pcmC0D0p` (playback) and `/dev/snd/pcmC0D0c` (capture)

### Channel Mapping in Linux

#### **Playback (TX) - 2 Channels**
```
ALSA Channel → TDM Slot → Physical Output
Channel 0   → Slot 0    → Left Speaker
Channel 1   → Slot 1    → Right Speaker
```

**Linux Usage:**
```bash
# Stereo playback (2 channels)
aplay -D hw:0,0 -f S32_LE -r 48000 -c 2 stereo_audio.wav
```

#### **Capture (RX) - 4 Channels**
```
ALSA Channel → TDM Slot → Physical Input
Channel 0   → Slot 0    → PDM Mic Left
Channel 1   → Slot 1    → PDM Mic Right  
Channel 2   → Slot 2    → I/V Monitor
Channel 3   → Slot 3    → Echo Reference
```

**Linux Usage:**
```bash
# Multi-channel capture (4 channels)
arecord -D hw:0,0 -f S32_LE -r 48000 -c 4 multichannel.wav
```

## TAS2563 Driver Slot Management

### Driver Slot Configuration

The TAS2563 driver uses your device tree properties to configure the codec:

```c
// From TAS2563 driver (simplified)
static int tas2563_set_dai_tdm_slot(struct snd_soc_dai *dai,
                                   unsigned int tx_mask, unsigned int rx_mask,
                                   int slots, int slot_width)
{
    // Configure codec registers based on device tree:
    // ti,left-slot = <0>   → Configure TX slot 0 for left audio
    // ti,right-slot = <1>  → Configure TX slot 1 for right audio
    // ti,imon-slot-no = <2> → Configure RX slot 2 for I-monitor
    // ti,vmon-slot-no = <2> → Configure RX slot 2 for V-monitor (combined)
    // ti,echo-ref = <3>    → Configure RX slot 3 for echo reference
}
```

### Codec Register Programming

Your device tree properties translate to TAS2563 register writes:

```
Device Tree Property → TAS2563 Register → Function
ti,left-slot = <0>   → TDM_CFG3[3:0]   → TX slot 0 = left audio
ti,right-slot = <1>  → TDM_CFG3[7:4]   → TX slot 1 = right audio  
ti,imon-slot-no = <2> → TDM_CFG6[5:0]  → RX slot 2 = current sense
ti,vmon-slot-no = <2> → TDM_CFG5[5:0]  → RX slot 2 = voltage sense
ti,echo-ref = <3>    → Custom register → RX slot 3 = echo reference
```

## ALSA Configuration Integration

Your ALSA configuration (`asound.conf`) defines how applications access the slots:

### Multi-Channel Capture Access
```bash
# Hardware capture endpoint for TAS2563 PDM mics + echo reference
pcm.tas2563_capture_hw {
    type hw
    card tas2563audio
    device 0
    channels 4        # Capture all 4 channels
}

# Channel layout for 4-channel capture:
#   Channel 0: Left PDM microphone    (Slot 0)
#   Channel 1: Right PDM microphone   (Slot 1)  
#   Channel 2: Current/Voltage sense  (Slot 2)
#   Channel 3: Echo reference         (Slot 3)
```

### Echo Reference Extraction
```bash
# Extract echo reference (channel 3) for AEC processing
pcm.eref_hw {
    type hw
    card tas2563audio
    device 0
    channels 4        # Multi-channel capture
}

# Use dsnoop to allow multiple readers of echo reference
pcm.eref_dsnoop {
    type dsnoop
    slave {
        pcm "eref_hw"
        channels 1    # Extract channel 3 (echo reference)
        rate 48000
        format S32_LE
    }
}
```

## SAI3 Hardware Register Configuration

### TDM Slot Enable (TMR Register)
```
TMR (Transmit Mask Register) = 0x00000000
Bit 31 30 29 28 ... 3  2  1  0
    0  0  0  0      0  0  0  0

All slots enabled:
Bit 0 = 0: Slot 0 enabled (Left audio)
Bit 1 = 0: Slot 1 enabled (Right audio)  
Bit 2 = 0: Slot 2 enabled (unused in TX)
Bit 3 = 0: Slot 3 enabled (unused in TX)
```

### SAI3 Configuration Registers
```
SAI3_TCR2 (Transmit Configuration 2):
- SYNC[1:0] = 00: Asynchronous mode
- BCP = 0: Bit clock active high
- BCD = 1: Bit clock generated internally (master mode)

SAI3_TCR4 (Transmit Configuration 4):  
- FRSZ[4:0] = 00011: Frame size = 4 words
- SYWD[4:0] = 11111: Sync width = 32 bits
- MF = 1: MSB first
- FSE = 0: Frame sync with first bit
- FSP = 0: Frame sync active high

SAI3_TCR5 (Transmit Configuration 5):
- WNW[4:0] = 11111: Word N width = 32 bits
- W0W[4:0] = 11111: Word 0 width = 32 bits
- FBT[4:0] = 11111: First bit transmitted = bit 31
```

## Application Usage Examples

### Simultaneous Playback and Capture
```bash
# Play stereo audio to speakers (slots 0,1)
aplay -D hw:tas2563audio,0 -f S32_LE -r 48000 -c 2 music.wav &

# Capture 4-channel audio (mics + echo ref + monitoring)
arecord -D hw:tas2563audio,0 -f S32_LE -r 48000 -c 4 capture.wav &
```

### Echo Cancellation Pipeline
```bash
# 1. Play audio (creates echo reference in slot 3)
aplay -D hw:tas2563audio,0 -f S32_LE -r 48000 -c 2 tts_output.wav &

# 2. Capture microphones + echo reference
arecord -D tas2563_capture_hw -f S32_LE -r 48000 -c 4 raw_capture.wav &

# 3. Extract echo reference for AEC processing
arecord -D eref -f S32_LE -r 48000 -c 1 echo_reference.wav &

# 4. Process channels 0,1 (mics) with channel 3 (echo ref) for AEC
webrtc_aec --far-end echo_reference.wav --near-end mic_channels.wav --output clean_audio.wav
```

## Signal Timing and Synchronization

### Frame Synchronization
```
FSYNC (48kHz) ┌─────┐                               ┌─────┐
              │     │                               │     │  
              └─────┘                               └─────┘

BCLK (6.144MHz) ┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐
                └┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘

TXD (Playback)  ├─Slot0─┤─Slot1─┤─Slot2─┤─Slot3─┤
                │L Audio│R Audio│  N/A  │  N/A  │

RXD (Capture)   ├─Slot0─┤─Slot1─┤─Slot2─┤─Slot3─┤  
                │Mic L  │Mic R  │I/V Mon│EchoRef│
```

### Critical Timing Points
1. **Frame Sync**: Aligns all slots across TX and RX
2. **Bit Clock**: 128 clocks per frame (4 × 32-bit slots)
3. **Echo Reference**: Slot 3 contains exact copy of audio sent to speakers
4. **Microphone Capture**: Slots 0,1 contain PDM microphone data
5. **Monitoring**: Slot 2 contains speaker current/voltage feedback

## Summary

Your device tree configuration creates a **perfectly synchronized multi-channel audio system**:

1. **Physical Signals**: SAI3 TXD/RXD carry 4-slot TDM frames
2. **Slot Assignment**: Device tree properties map signals to specific slots
3. **Linux Integration**: ALSA creates 2-channel playback + 4-channel capture devices
4. **Application Access**: Applications can access individual channels for AEC processing
5. **Synchronization**: All signals frame-synchronized for precise echo cancellation

The Linux audio subsystem automatically handles the TDM slot management based on your device tree configuration, providing clean separation of audio streams while maintaining perfect timing alignment for echo cancellation.
