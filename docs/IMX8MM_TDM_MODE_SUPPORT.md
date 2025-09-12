# i.MX8MM TDM Mode Support - Official Documentation

## What is TDM Mode Support?

**TDM (Time Division Multiplexing)** mode is a digital audio protocol that allows multiple audio channels to share a single data line by dividing time into discrete slots. The i.MX8MM SAI provides comprehensive TDM support for multi-channel audio applications.

## Official TDM Mode Definition (from i.MX8MM Reference Manual)

### Channel Mode Configuration (CHMOD bit)

The SAI supports two distinct modes for data pin behavior:

#### **TDM Mode (CHMOD = 0)** ✅ *Your Configuration*
```
"TDM mode, transmit data pins are tri-stated when slots are masked or channels are disabled."
```

**Key Characteristics:**
- **Tri-state Control**: Data pins go to high-impedance (tri-state) when slots are not active
- **Slot Masking**: Individual slots can be enabled/disabled dynamically
- **Multi-device Sharing**: Multiple devices can share the same data bus
- **Standard TDM Protocol**: Follows industry-standard TDM timing

#### **Output Mode (CHMOD = 1)**
```
"Output mode, transmit data pins are never tri-stated and will output zero when slots are masked or channels are disabled."
```

**Key Characteristics:**
- **Always Driving**: Data pins always output (never tri-state)
- **Zero Output**: Outputs zero when slots are masked
- **Single Device**: Suitable for point-to-point connections

## TDM Slot Masking System

### Word Mask Register (TMR) - Double Buffered

The i.MX8MM provides sophisticated slot control through the **Transmit Mask Register (TMR)**:

```
"The SAI transmitter and receiver each contain a word mask register, namely TMR and RMR, 
that can be used to mask any word in the frame. Because the word mask register is 
double buffered, software can update it before the end of each frame to mask a particular 
word in the next frame."
```

#### **TMR Functionality:**
- **Per-Slot Control**: Each bit controls one slot (word) in the frame
- **Double Buffered**: Changes take effect at frame boundaries (glitch-free)
- **Dynamic Masking**: Can change slot assignments frame-by-frame
- **Tri-state Control**: Masked slots tri-state the data pin
- **FIFO Management**: FIFO not read for masked slots (efficient)

#### **TMR Register Format:**
```
Bits: 31 30 29 28 ... 3  2  1  0
      │  │  │  │      │  │  │  └─ Word 0 mask
      │  │  │  │      │  │  └──── Word 1 mask  
      │  │  │  │      │  └─────── Word 2 mask
      │  │  │  │      └────────── Word 3 mask
      │  │  │  └─────────────────── Word 28 mask
      │  │  └────────────────────── Word 29 mask
      │  └───────────────────────── Word 30 mask
      └──────────────────────────── Word 31 mask

0 = Word enabled (active slot)
1 = Word masked (tri-stated slot)
```

### Receive Mask Register (RMR)

Similar functionality for receive direction:
```
"The RMR causes the received data for each selected word to be discarded and not written 
to the receive FIFO."
```

## TDM Frame Structure Support

### Frame Capabilities
- **Maximum Frame Size**: **32 words per frame**
- **Word Size**: **8-32 bits per word**
- **Flexible Timing**: Configurable frame sync and bit clock
- **Bidirectional**: Independent TX and RX TDM streams

### Your Profile 8 Configuration
```
Frame: 4 words × 32-bit = 128-bit frame
TMR Setting: 0x00000000 (all slots enabled)

Slot Layout:
┌─────────┬─────────┬─────────┬─────────┐
│ Word 0  │ Word 1  │ Word 2  │ Word 3  │
│ Enabled │ Enabled │ Enabled │ Enabled │
│ L Audio │ R Audio │ I/V Mon │ Echo Ref│
└─────────┴─────────┴─────────┴─────────┘
```

## TDM Mode Benefits for Your Application

### 1. **Multi-Device Bus Sharing**
```
i.MX8MM SAI3 ──┬── TAS2563 (Profile 8)
               ├── Future Codec 2 (different slots)
               └── Future Codec 3 (different slots)
```

### 2. **Dynamic Slot Management**
- **Runtime Reconfiguration**: Change active slots without stopping audio
- **Power Efficiency**: Disable unused slots to save power
- **Flexible Routing**: Route different audio streams to different slots

### 3. **Synchronous Operation**
- **Frame Sync**: All devices synchronized to same frame timing
- **Bit Clock**: Shared bit clock ensures perfect timing alignment
- **Echo Cancellation**: Precise timing for echo reference correlation

## TDM vs I2S Comparison

| Feature | I2S Mode | TDM Mode |
|---------|----------|----------|
| **Slots** | 2 (L/R) | Up to 32 |
| **Devices** | 1 per bus | Multiple per bus |
| **Tri-state** | No | Yes (when masked) |
| **Slot Control** | Fixed | Dynamic masking |
| **Efficiency** | Simple | Flexible |
| **Your Use Case** | Basic stereo | ✅ Echo cancellation |

## Frame Sync Configuration

### Frame Sync Early (FSE)
```
FSE = 0: Frame sync asserts with the first bit of the frame
FSE = 1: Frame sync asserts one bit before the first bit of the frame
```

### TDM Timing Diagram
```
FSE = 0 (Standard):
FSYNC  ┌─────┐                               ┌─────┐
       │     │                               │     │
       └─────┘                               └─────┘

BCLK   ┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐
       └┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘

DATA   ├─Word0─┤─Word1─┤─Word2─┤─Word3─┤
       │32-bit │32-bit │32-bit │32-bit │
```

## Advanced TDM Features

### 1. **On-Demand Frame Sync**
```
"When set, and the frame sync is generated internally, a frame sync is only generated 
when the FIFO warning flag is clear."
```
- **Adaptive Timing**: Frame sync only when data ready
- **Flow Control**: Prevents underrun conditions
- **Efficient Operation**: No empty frames transmitted

### 2. **Timestamp Counters**
```
"The transmitter and receiver implement separate timestamp counters and bit counters."
```
- **Precise Timing**: Track exact bit and frame positions
- **Synchronization**: Correlate audio streams for echo cancellation
- **Debugging**: Monitor TDM frame timing accuracy

### 3. **FIFO Integration**
- **128 × 32-bit FIFO** per data line
- **Masked Slot Optimization**: FIFO not accessed for masked slots
- **Efficient DMA**: Only active slots consume memory bandwidth

## Your Configuration Analysis

### ✅ **Optimal TDM Setup for Echo Cancellation**

```dts
// Your device tree enables proper TDM mode
dai-tdm-slot-num = <4>;        // 4 active slots
dai-tdm-slot-width = <32>;     // 32-bit slots
simple-audio-card,format = "i2s";  // I2S timing with TDM slots
```

**Resulting Configuration:**
- **CHMOD = 0**: TDM mode with tri-state control ✅
- **TMR = 0x00000000**: All 4 slots enabled ✅
- **Frame Size**: 4 words (12.5% of 32-word maximum) ✅
- **Slot Masking**: Available for future expansion ✅

### **Why TDM Mode is Perfect for Profile 8:**

1. **Bidirectional Audio**: TX slots 0,1 + RX slots 2,3
2. **Precise Timing**: Frame sync ensures echo reference correlation
3. **Expandability**: 28 additional slots available for future codecs
4. **Tri-state Control**: Clean bus sharing if multiple codecs added
5. **Dynamic Control**: Can mask/unmask slots for power management

## Summary

**TDM Mode Support** in the i.MX8MM SAI provides:

- ✅ **Multi-slot audio** (up to 32 words per frame)
- ✅ **Dynamic slot masking** with double-buffered TMR register
- ✅ **Tri-state control** for clean bus sharing
- ✅ **Bidirectional operation** for simultaneous TX/RX
- ✅ **Frame-accurate timing** for echo cancellation
- ✅ **Efficient FIFO management** for masked slots
- ✅ **Expandable architecture** for future audio devices

Your SAI3 configuration leverages TDM mode optimally for TAS2563 Profile 8 echo cancellation, providing the precise timing control and slot management needed for high-quality audio processing.
