# TAS2563 Audio Driver Context - Sentai Board

## Project Overview
This document tracks the TAS2563 audio driver implementation and customization work for the i.MX8MM Jaguar Sentai board.

## Current Implementation Status

### Driver Architecture (As of Current Build)
- **Active Driver**: Upstream Linux kernel `snd-soc-tas2562` driver
- **Driver Type**: Mainline kernel module (CONFIG_SND_SOC_TAS2562=m)
- **Custom Driver Status**: Available but NOT active (kernel-module-tas2563)
- **Transition**: Moved from custom Android-based driver to upstream Linux driver

### Hardware Configuration
- **Board**: i.MX8MM Jaguar Sentai
- **Audio Chip**: TAS2563 (Texas Instruments)
- **I2C Address**: 0x4C
- **Audio Interface**: SAI3 (Serial Audio Interface 3)
- **Audio Format**: I2S
- **Channels**: 1 (mono configuration)
- **GPIO Control**: GPIO5_4 for shutdown control (currently commented out)

### Kernel Configuration
```
# Enabled in: recipes-kernel/linux/linux-lmp-fslc-imx/imx8mm-jaguar-sentai/enable_tas2562.cfg
CONFIG_SND_SOC_TAS2562=m

# Also in: recipes-kernel/linux/linux-lmp-fslc-imx/06-enable-tas256x_2781.cfg
CONFIG_SND_SOC_TAS2562=m
```

### Device Tree Configuration
**File**: `recipes-bsp/device-tree/lmp-device-tree/imx8mm-jaguar-sentai.dts`

```dts
sound-tas2563 {
    compatible = "simple-audio-card";
    simple-audio-card,name = "tas2563-audio";
    simple-audio-card,format = "i2s";
    simple-audio-card,frame-master = <&cpudai2>;
    simple-audio-card,bitclock-master = <&cpudai2>;
    
    cpudai2: simple-audio-card,cpu {
        sound-dai = <&sai3>;
        dai-tdm-slot-num = <2>;
        dai-tdm-slot-width = <32>;
    };
    
    simple-audio-card,codec {
        sound-dai = <&tas2563>;
        clocks = <&clk IMX8MM_CLK_SAI3_ROOT>;
    };
};

// I2C2 device definition
tas2563: tas2563@4C {
    #sound-dai-cells = <0>;
    compatible = "ti,tas2563";
    reg = <0x4C>;
    ti,channels = <1>;
    // ti,reset-gpio = <&gpio5 4 GPIO_ACTIVE_HIGH>; // Currently commented out
}

// GPIO shutdown control
&gpio5 {
    audio-shutdown-hog {
        gpio-hog;
        gpios = <4 GPIO_ACTIVE_LOW>;
        output-low;
        line-name = "tas2563-shutdown";
    };
}
```

### Audio System Integration

#### Driver Loading Process
**File**: `recipes-multimedia/alsa/alsa-utils/imx8mm-jaguar-sentai/load-audio-drivers.sh`
```bash
# Load the drivers
modprobe snd-soc-fsl-micfil
modprobe snd-soc-tas2563  # NOTE: This may need updating to snd-soc-tas2562
```

**⚠️ POTENTIAL ISSUE**: Script tries to load `snd-soc-tas2563` but kernel only has `snd-soc-tas2562` enabled.

#### SystemD Integration
- **Service**: `audio-driver.service`
- **Auto-enable**: Enabled for Sentai board
- **Purpose**: Load audio drivers in controlled order to maintain consistent device IDs

#### ALSA Configuration
**File**: `recipes-bsp/alsa-state/alsa-state/imx8mm-jaguar-sentai/asound.conf`
- **Default card**: `tas2563audio`
- **Software volume**: -60dB to 0dB range
- **Microphone**: Separate MICFIL interface
- **Loopback support**: For AEC (Acoustic Echo Cancellation)

### Machine Configuration
**File**: `conf/machine/imx8mm-jaguar-sentai.conf`
- **MACHINE_FEATURES**: Does NOT include `"tas2563"` (custom driver not enabled)
- **KERNEL_MODULE_AUTOLOAD**: Includes `snd-aloop` for audio loopback
- **Module configuration**: spidev buffer size customization

## Available Custom Driver (Not Currently Used)

### Custom Driver Details
**File**: `recipes-kernel/kernel-modules/kernel-module-tas2563_git.bb`
- **Source**: `git://github.com/DynamicDevices/tas2563-android-driver.git`
- **Commit**: `193335838bd79836f14f82c2b84e1b16817e48b6`
- **Module**: `snd-soc-tas2563`
- **Firmware**: `tas2563_uCDSP.bin` (installed to `/lib/firmware/`)
- **Type**: Android-based out-of-tree driver

### Custom Driver Activation
To enable the custom driver:
1. Add `"tas2563"` to `MACHINE_FEATURES` in `conf/machine/imx8mm-jaguar-sentai.conf`
2. This would include `recipes-samples/images/lmp-feature-tas2563.inc`
3. Would install `kernel-module-tas2563` package
4. Update driver loading script to use correct module name

## Related Hardware Support

### Other TAS Drivers in Repository
- **TAS2781**: Supported on Phasora board (`MACHINE_FEATURES` includes `"tas2781"`)
- **TAS2562**: Current upstream driver used for TAS2563

### Audio Pipeline Components
- **SAI3**: Serial Audio Interface for I2S communication
- **MICFIL**: Microphone interface (separate from speaker)
- **PulseAudio**: Audio server (enabled via DISTRO_FEATURES)
- **ALSA**: Low-level audio system

## TAS2563 Firmware Operation

### **CRITICAL DISCOVERY: Firmware Download Process**

**Yes, the TAS2563 driver DOES download firmware to the device during operation.**

#### Firmware Architecture
- **Purpose**: Enable TAS2563's Digital Signal Processing (DSP) capabilities
- **Process**: Driver parses firmware and downloads it to TAS2563, then powers on device
- **Content**: Hardware components, register settings, and DSP firmware stored in binary
- **Generation**: Firmware can be customized using Texas Instruments' PurePath tool

#### Current Firmware Status
Based on research and repository analysis:

1. **Upstream Driver Path (Currently Active)**:
   - **Driver**: `snd-soc-tas2562` kernel module
   - **Initial Mode**: TAS2563 operates in **bypass-DSP mode** (no DSP features)
   - **Linux Firmware Available**: Multiple TAS2XXX firmware files available in `/lib/firmware/ti/tas2563/`:
     - `TAS2XXX3870.bin`
     - `INT8866RCA2.bin`
   - **Migration Path**: TI recommends moving TAS2563 support to `tas2781` driver for full DSP support

2. **Custom Driver Path (Available but NOT Active)**:
   - **Driver**: `snd-soc-tas2563` out-of-tree module
   - **Custom Firmware**: `tas2563_uCDSP.bin` (Dynamic Devices specific)
   - **Location**: Would install to `/lib/firmware/tas2563_uCDSP.bin`
   - **Features**: Full DSP capabilities with custom configuration

#### Firmware Files Found in Repository
- **Custom Firmware**: 
  - `recipes-kernel/kernel-modules/kernel-module-tas2563/tas2563_uCDSP.bin`
  - `recipes-kernel/kernel-modules/kernel-module-tas2563/imx8mm-jaguar-sentai/tas2563_uCDSP.bin`
- **Linux Firmware**: Multiple TAS2XXX*.bin files available via linux-firmware package

#### Calibration Requirements
- **Calibration File**: `tas2563_cal.bin` may be required for optimal operation
- **Storage Location**: Typically `/mnt/vendor/persist/audio` (Android path) or `/lib/firmware/`
- **Purpose**: Contains device-specific calibration data for hardware configuration

## Development Tasks & Issues

### Current Issues to Investigate
1. **✅ FIXED - Driver Loading Mismatch**: ~~Script loads `snd-soc-tas2563` but kernel has `snd-soc-tas2562`~~
   - **Issue**: `load-audio-drivers.sh` was trying to load `snd-soc-tas2563` module
   - **Reality**: Only `snd-soc-tas2562` module exists on target system
   - **Result**: `audio-driver.service` was failing on boot
   - **Resolution**: Updated script to load correct `snd-soc-tas2562` module
2. **GPIO Reset**: Reset GPIO commented out - may need for proper initialization
3. **⚠️ FIRMWARE FUNCTIONALITY**: Current upstream driver may be operating TAS2563 in bypass-DSP mode
4. **Missing Calibration**: No calibration file (`tas2563_cal.bin`) found in current configuration

### **Target System Verification (192.168.0.58)**
**Status**: ✅ Audio system is functioning despite script failure

- **Loaded Modules**: `snd_soc_tas2562` correctly loaded and active
- **Audio Cards Detected**:
  - Card 0: `Loopback` (for AEC processing)
  - Card 1: `tas2563audio` (TAS2563 amplifier) ✅
  - Card 2: `micfilaudio` (microphone input) ✅
- **Driver Module**: `/lib/modules/6.6.52-lmp-standard/kernel/sound/soc/codecs/snd-soc-tas2562.ko`
- **Device Tree Compatibility**: `tas2562` driver correctly handles `"ti,tas2563"` compatible string
- **Service Status**: `audio-driver.service` was failing due to module name mismatch

**Conclusion**: The TAS2563 hardware is working correctly with the upstream driver, but the loading script had an incorrect module name.

### **Firmware Decision Matrix**

| Requirement | Upstream Driver (tas2562) | Custom Driver (tas2563) |
|-------------|---------------------------|--------------------------|
| **DSP Features** | ❌ Bypass mode only | ✅ Full DSP functionality |
| **Maintenance** | ✅ Kernel mainline | ⚠️ Out-of-tree maintenance |
| **Firmware** | ✅ Standard linux-firmware | ✅ Custom `tas2563_uCDSP.bin` |
| **Audio Quality** | ⚠️ Basic amplifier | ✅ Advanced DSP processing |
| **Updates** | ✅ Automatic kernel updates | ❌ Manual driver updates |
| **Customization** | ❌ Limited | ✅ Full PurePath tool support |

### **RECOMMENDATION**: 
For **basic audio functionality**, current upstream driver is sufficient.
For **advanced DSP features** (EQ, filtering, protection), switch to custom driver.

### Potential Customization Areas
1. **Driver Selection**: Choose upstream vs custom based on DSP requirements
2. **Firmware Customization**: Use TI PurePath tool to create custom DSP firmware
3. **Calibration**: Generate device-specific calibration files
4. **Audio Routing**: Modify ALSA configuration for specific use cases
5. **GPIO Control**: Enable reset/shutdown GPIO for power management
6. **Audio Processing**: AEC and voice processing pipeline tuning

## Testing & Validation

### Audio Functionality Tests
- [ ] Basic playback functionality
- [ ] Audio card detection (`aplay -l`)
- [ ] Volume controls
- [ ] Audio quality assessment
- [ ] Power management (shutdown/resume)

### Driver Verification
- [ ] Module loading (`lsmod | grep tas`)
- [ ] Device tree binding verification
- [ ] I2C communication (`i2cdetect -y 1`)
- [ ] ALSA mixer controls (`amixer`)

## References

### Key Files
- **Kernel Config**: `recipes-kernel/linux/linux-lmp-fslc-imx/imx8mm-jaguar-sentai/enable_tas2562.cfg`
- **Device Tree**: `recipes-bsp/device-tree/lmp-device-tree/imx8mm-jaguar-sentai.dts`
- **ALSA Config**: `recipes-bsp/alsa-state/alsa-state/imx8mm-jaguar-sentai/asound.conf`
- **Driver Loading**: `recipes-multimedia/alsa/alsa-utils/imx8mm-jaguar-sentai/load-audio-drivers.sh`
- **Custom Driver**: `recipes-kernel/kernel-modules/kernel-module-tas2563_git.bb`

### Documentation
- [TAS2563 Datasheet](https://www.ti.com/product/TAS2563)
- [Linux ALSA SoC Documentation](https://www.kernel.org/doc/html/latest/sound/soc/)
- [i.MX8MM SAI Documentation](https://www.nxp.com/docs/en/reference-manual/IMX8MMRM.pdf)

---
## TAS2563 Test Hardware Configuration

### **NEW: Test Unit with TAS2563 Integrated Microphones**

**Hardware Changes**: Test unit has microphones connected directly to TAS2563 inputs instead of i.MX8MM PDM interface.

#### **Detailed Hardware Connection Changes**

**Original Configuration (PDM via i.MX8MM)**:
- **Mic Data**: Connected to `SAI1_RXD0` (function: PDM_D0)
- **Mic Clock**: Connected to `SAI1_MCLK` (function: PDM_CLK)
- **Interface**: i.MX8MM PDM/MICFIL peripheral
- **Processing**: Basic ADC conversion in i.MX8MM

**Test Hardware Configuration (TAS2563 Direct)**:
- **Mic Data**: Connected to TAS2563 `PDMD` pin 24
- **Mic Clock**: Connected to TAS2563 `PDMCLK` pin 9  
- **Interface**: TAS2563 internal PDM interface
- **Processing**: TAS2563 DSP with advanced audio processing

**Microphone Setup**:
- **Configuration**: Two microphones connected in parallel to same data/clock lines
- **Timing**: One microphone set to **rising edge**, one to **falling edge**
- **Benefit**: Allows two microphones on single data line with time-division multiplexing

#### **Dual Hardware Support Implementation**

**✅ SINGLE CONFIGURATION APPROACH**: Modified original files to support both hardware variants

1. **Enhanced Device Tree**: `imx8mm-jaguar-sentai.dts` (modified)
   - Supports both original PDM and TAS2563 microphone configurations
   - Enables both MICFIL (for original) and SAI3 bidirectional (for test hardware)
   - TAS2563 configured with runtime-controllable microphone settings
   - PDM pin configuration maintained for original hardware compatibility

2. **Auto-Detecting ALSA Configuration**: `asound.conf` (modified)
   - Uses environment variables to select microphone source at runtime
   - Supports both `micfilaudio` (original) and `tas2563audio` (test hardware)
   - Maintains all existing speaker and loopback functionality
   - Automatic fallback to original hardware if detection fails

3. **Hardware Detection Script**: `detect-audio-hardware.sh`
   - Automatically detects hardware variant at boot
   - Sets environment variables for ALSA configuration
   - Supports multiple detection methods (device tree, ALSA probing, GPIO)
   - Configures TAS2563 microphone mode when detected
   - Creates persistent configuration in `/etc/default/audio-hardware`

4. **Enhanced Driver Loading**: `load-audio-drivers.sh` (modified)
   - Integrates hardware detection into boot process
   - Loads appropriate drivers and applies configuration
   - Sets up environment variables for user sessions

#### **Key Device Tree Changes**

**Pin Mapping Changes**:
```dts
// Original PDM configuration (now disabled)
pinctrl_pdm: pdmgrp {
    fsl,pins = <
        MX8MM_IOMUXC_SAI1_MCLK_PDM_CLK      0xd6    // Was mic clock
        MX8MM_IOMUXC_SAI1_RXD0_PDM_DATA0    0xd6    // Was mic data
    >;
};

// Test configuration: Enhanced SAI3 for bidirectional audio
&sai3 {
    fsl,sai-synchronous-rx;  /* Enable receive capability */
    assigned-clocks = <&clk IMX8MM_CLK_SAI3>;
    assigned-clock-parents = <&clk IMX8MM_AUDIO_PLL1_OUT>;
    assigned-clock-rates = <12288000>;
    // ... other configs
};

// TAS2563 with PDM microphone support
tas2563: tas2563@4C {
    ti,channels = <1>;
    ti,reset-gpio = <&gpio5 4 GPIO_ACTIVE_HIGH>;
    ti,irq-gpio = <&gpio5 5 GPIO_ACTIVE_LOW>;
    
    // PDM Microphone Configuration
    ti,mic-mode = <1>; /* Enable microphone input mode */
    ti,mic-bias-enable = <1>; /* Enable microphone bias */
    ti,mic-gain = <0x10>; /* Microphone input gain */
    ti,pdm-edge = <3>; /* Both rising and falling edge (dual mic) */
    ti,pdm-clk-rate = <3072000>; /* PDM clock rate */
    
    // I2S Configuration  
    ti,asi-format = <0>; /* 0=I2S, 1=DSP */
    ti,left-slot = <0>;
    ti,right-slot = <1>;
    ti,i2s-bits = <32>;
    // ... other configs
};
```

**Hardware Connection Summary**:
```
Original (i.MX8MM PDM):        Test Hardware (TAS2563 PDM):
┌─────────────────────┐       ┌─────────────────────────┐
│  SAI1_MCLK (PDM_CLK)│────── │  TAS2563 PDMCLK (pin 9) │
│  SAI1_RXD0 (PDM_D0) │────── │  TAS2563 PDMD (pin 24)  │
│  i.MX8MM MICFIL     │       │  TAS2563 PDM Interface   │
└─────────────────────┘       └─────────────────────────┘
         │                              │
         ▼                              ▼
    Basic ADC                    Advanced DSP Processing
```

#### **Deployment Instructions**

1. **Single Image Deployment**:
   ```bash
   # No special configuration needed - same image works for both hardware variants
   # Build and deploy normally using modified imx8mm-jaguar-sentai.dts
   # System will auto-detect hardware variant on first boot
   ```

2. **Manual Hardware Detection**:
   ```bash
   # Copy detection script to target
   scp detect-audio-hardware.sh fio@192.168.0.58:~/
   
   # Run detection manually
   ssh fio@192.168.0.58 './detect-audio-hardware.sh'
   
   # Force re-detection
   ssh fio@192.168.0.58 './detect-audio-hardware.sh --force'
   
   # Manually specify hardware type
   ssh fio@192.168.0.58 './detect-audio-hardware.sh --type tas2563_mic'
   ssh fio@192.168.0.58 './detect-audio-hardware.sh --type micfil_mic'
   ```

3. **Testing Both Configurations**:
   ```bash
   # Test current detected configuration
   ssh fio@192.168.0.58 'arecord -D mic -f S16_LE -r 16000 -c 2 -d 5 test.wav'
   
   # Test specific hardware (original)
   ssh fio@192.168.0.58 'arecord -D micfil_mic -f S32_LE -r 48000 -c 8 -d 5 test_original.wav'
   
   # Test specific hardware (test HW)
   ssh fio@192.168.0.58 'arecord -D tas2563_mic -f S16_LE -r 16000 -c 2 -d 5 test_tas2563.wav'
   
   # Check configuration
   ssh fio@192.168.0.58 'cat /etc/default/audio-hardware'
   ```

#### **Expected Behavior Changes**

| Component | Before (PDM) | After (TAS2563 Mics) |
|-----------|--------------|----------------------|
| **Microphone Card** | `micfilaudio` | `tas2563audio` |
| **Capture Device** | `hw:micfilaudio,0` | `hw:tas2563audio,0,1` |
| **Hardware Interface** | i.MX8MM MICFIL/PDM | TAS2563 PDM interface |
| **Pin Connections** | SAI1_MCLK/SAI1_RXD0 | TAS2563 PDMCLK(9)/PDMD(24) |
| **Microphone Count** | 2 mics via PDM_D0 | 2 mics via rising/falling edge |
| **Audio Processing** | Basic i.MX8MM ADC | TAS2563 DSP capabilities |
| **Microphone Bias** | External/board-level | TAS2563 internal bias |
| **Clock Source** | i.MX8MM generates PDM_CLK | TAS2563 generates PDMCLK |
| **Data Path** | PDM → MICFIL → SAI → CPU | PDM → TAS2563 DSP → SAI3 → CPU |

#### **Troubleshooting**

- **No capture device**: Check SAI3 bidirectional configuration
- **No audio data**: Verify microphone bias and gain settings
- **Device not found**: Ensure TAS2563 device tree properties are correct
- **ALSA errors**: Check subdevice numbers and capture formats

---
**Last Updated**: December 2024  
**Maintainer**: Dynamic Devices Audio Team  
**Status**: Active Development - Test Hardware Support Added
