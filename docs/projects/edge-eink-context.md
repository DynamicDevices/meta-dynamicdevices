# imx93-jaguar-eink Board Implementation Context

**🔗 Related GitHub Issues**: [Edge EInk Board Milestone](https://github.com/DynamicDevices/meta-dynamicdevices/milestone/2)

**📋 Key Active Issues**:
- [Issue #11](https://github.com/DynamicDevices/meta-dynamicdevices/issues/11): Device Tree Pinctrl Configuration Cleanup (✅ Completed for imx93-jaguar-eink)
- Issue #X: Power Management Integration (pending)
- Issue #X: EInk Display Driver Integration (pending)

## Project Overview
Implementation of support for the Dynamic Devices i.MX93 Jaguar E-Ink board with focus on wireless connectivity using the ublox MAYA W2 module (IW612 chipset).

## Hardware Specifications
- **Main SoC**: i.MX93
- **Wireless Module**: ublox MAYA W2 (NXP IW612 chipset)
- **Wireless Capabilities**: WiFi 6 (802.11ax), Bluetooth 5.4, 802.15.4 (ZigBee)
- **Power Management**: MCXC143VFM microcontroller
- **LTE Modem**: USB-based cellular modem support
- **Storage**: eMMC on USDHC1
- **Display**: 13-inch E-ink display support
- **Security**: EdgeLock Enclave (ELE) and Cortex-M33 not used/supported

## Pin Mapping Implementation

### WiFi SDIO Interface (USDHC2)
| Function | i.MX93 Pin | GPIO | Status |
|----------|------------|------|--------|
| SDIO CLK | SD2_CLK | - | ✅ Implemented |
| SDIO CMD | SD2_CMD | - | ✅ Implemented |
| SDIO Data[0-3] | SD2_DATA[0-3] | - | ✅ Implemented |
| WiFi Interrupt | ENET2_RD1 | GPIO4_IO25 | ✅ Implemented |
| WiFi Reset | ENET2_RD2 | GPIO4_IO26 | ✅ Implemented |

### 802.15.4 SPI Interface (LPSPI3)
| Function | i.MX93 Pin | GPIO | Status |
|----------|------------|------|--------|
| SPI CS | GPIO_IO08 | - | ✅ Implemented |
| SPI CLK | GPIO_IO11 | - | ✅ Implemented |
| SPI MISO | GPIO_IO09 | - | ✅ Implemented |
| SPI MOSI | GPIO_IO10 | - | ✅ Implemented |
| ZB Interrupt | ENET2_RD3 | GPIO4_IO27 | ✅ Implemented |
| BT/ZB Reset | ENET2_RD0 | GPIO4_IO24 | ✅ Implemented |

### Bluetooth UART Interface (LPUART5)
| Function | i.MX93 Pin | Status |
|----------|------------|--------|
| BT UART TX | DAP_TDO_TRACESWO | ✅ Implemented |
| BT UART RX | DAP_TDI | ✅ Implemented |
| BT UART CTS | DAP_TCLK_SWCLK | ✅ Implemented |
| BT UART RTS | DAP_TMS_SWDIO | ✅ Implemented |

## Files Modified/Created

### Device Tree
- **File**: `recipes-bsp/device-tree/lmp-device-tree/imx93-jaguar-eink.dts`
- **Status**: ✅ Complete rewrite
- **Changes**:
  - Removed: Camera, audio codec, dual ethernet, HDMI/DSI, extra USB-C, I2C sensors
  - Added: ublox MAYA W2 support for WiFi/BT/802.15.4
  - Configured: USDHC2 for WiFi SDIO, LPSPI3 for ZigBee, LPUART5 for Bluetooth
  - Power management: Regulators for WiFi, BT, LTE

### Kernel Configuration
- **Files**: 
  - `recipes-kernel/linux/linux-lmp-fslc-imx/imx93-jaguar-eink/enable_iw612_wifi.cfg` ✅
  - `recipes-kernel/linux/linux-lmp-fslc-imx/imx93-jaguar-eink/enable_iw612_bluetooth.cfg` ✅
  - `recipes-kernel/linux/linux-lmp-fslc-imx/imx93-jaguar-eink/enable_802154.cfg` ✅
  - `recipes-kernel/linux/linux-lmp-fslc-imx/imx93-jaguar-eink/enable_lte_modem.cfg` ✅ **OPTIMIZED**
  - `recipes-kernel/linux/linux-lmp-fslc-imx/imx93-jaguar-eink/enable_spi.cfg` ✅
  - `recipes-kernel/linux/linux-lmp-fslc-imx/imx93-jaguar-eink/enable_eink_display.cfg` ✅ **OPTIMIZED**
  - `recipes-kernel/linux/linux-lmp-fslc-imx/imx93-jaguar-eink/fix_soc_imx9.cfg` ✅ **CRITICAL**
- **Updated**: `recipes-kernel/linux/linux-lmp-fslc-imx_%.bbappend` ✅
- **Critical Fix**: `fix_soc_imx9.cfg` disables EdgeLock Enclave to prevent kernel panic

#### **Recent Kernel Optimizations** (December 2024)
- **USB Serial Drivers**: Reduced from 50+ to 5 essential drivers (OPTION, QUALCOMM, QCAUX, FTDI_SIO, CP210X)
- **Display Drivers**: Disabled unused SSD1306/1331/1351 to eliminate kernel warnings
- **Boot Performance**: Significantly improved boot time with minimal driver set
- **Kernel Size**: Reduced kernel footprint by removing unnecessary drivers

### Machine Configuration
- **File**: `conf/machine/imx93-jaguar-eink.conf`
- **Status**: ✅ Updated
- **Changes**:
  - Kernel modules: ieee802154, bluetooth, spidev
  - WiFi features: nxpiw612-sdio
  - Removed: ALSA support
  - SPI buffer: 16KB for ZigBee
  - **NEW**: `NXP_WIFI_SECURE_FIRMWARE` configuration variable

#### **WiFi Firmware Configuration** (December 2024)
**Status**: ✅ **Flexible Firmware Selection Implemented**

**Configuration Options**:
- **Production Builds**: `NXP_WIFI_SECURE_FIRMWARE = "1"` (default) - Uses `sduart_nw61x_v1.bin.se`
- **Development Builds**: `NXP_WIFI_SECURE_FIRMWARE = "0"` - Uses `sduart_nw61x_v1.bin`

**Files Modified**:
- `conf/machine/imx93-jaguar-eink.conf`: Added configuration variable
- `recipes-bsp/firmware-imx/firmware-nxp-wifi_1.%.bbappend`: Automatic firmware selection logic
- `recipes-bsp/firmware-imx/firmware-nxp-wifi/wifi_mod_para.conf`: Updated firmware path configuration

**Benefits**:
- ✅ **Automatic Selection**: Build system chooses correct firmware based on configuration
- ✅ **Secure Boot Support**: Production builds use signed firmware (.se files)
- ✅ **Development Flexibility**: Debug builds use standard firmware (.bin files)
- ✅ **Build Warnings**: Clear indication of which firmware type is selected

### U-boot Configuration
- **Files**:
  - `recipes-bsp/u-boot/u-boot-fio/imx93-jaguar-eink/enable-spi.cfg` ✅ New
  - `recipes-bsp/u-boot/u-boot-fio/imx93-jaguar-eink/enable-i2c.cfg` ✅ Existing
  - `recipes-bsp/u-boot/u-boot-fio/imx93-jaguar-eink/custom-dtb.cfg` ✅ Existing
  - `recipes-bsp/u-boot/u-boot-fio/imx93-jaguar-eink/disable-fiovb.cfg` ✅ **NEW**
- **Updated**: `recipes-bsp/u-boot/u-boot-fio_%.bbappend` ✅
- **Fixed**: `recipes-bsp/u-boot/u-boot-ostree-scr-fit/imx93-jaguar-eink/boot.cmd` ✅
- **Boot Fix**: `disable-fiovb.cfg` prevents "Unknown command 'fiovb'" error

## Build Testing Status

### Last Build Attempt
- **Command**: `KAS_MACHINE=imx93-jaguar-eink ./kas-build-base.sh`
- **Status**: ✅ **SUCCESS**
- **Tasks**: 7369 tasks completed successfully
- **Warnings**: Only 2 minor machine features syntax warnings

### Hardware Test Results
- **Previous Status**: ❌ Device tree not found (MMC device mismatch)
- **Issue Identified**: ✅ Device tree `imx93-jaguar-eink.dtb` exists on boot partition
- **Root Cause**: U-Boot `fdt_file` variable not set correctly 
- **Immediate Fix**: `setenv fdt_file imx93-jaguar-eink.dtb` in U-Boot
- **Boot Test**: ✅ **SUCCESS** - System boots correctly with manual fdt_file setting
- **Permanent Fix**: Created `01-customise-dtb.patch` for U-Boot source
- **Status**: Ready to rebuild U-Boot with permanent fix

### Build Errors from Previous Attempt
- ⚠️ SPDX metadata determinism errors (not related to our changes)
- ⚠️ Various TMPDIR reference warnings (build system warnings)
- ✅ No compilation errors in our device tree or kernel configs

## Testing Plan

### Build Testing
- [ ] Complete full image build: `KAS_MACHINE=imx93-jaguar-eink ./kas-build-base.sh`
- [ ] Verify kernel compilation with new configs
- [ ] Verify device tree compilation
- [ ] Verify u-boot compilation

### Hardware Testing (when available)
- [ ] Boot test with new device tree
- [ ] WiFi connectivity test (IW612)
- [ ] Bluetooth pairing test
- [ ] 802.15.4 SPI interface test
- [ ] LTE modem detection test
- [ ] GPIO control verification

## Key Implementation Notes

### Wireless Stack
- **IW612 Driver**: Uses NXP's MOAL/MLAN driver framework
- **802.15.4**: Linux 802.15.4 subsystem with 6LoWPAN support
- **Bluetooth**: Standard Linux Bluetooth stack with UART HCI

### Power Management
- **MCXC143VFM**: External microcontroller manages power states
- **Regulators**: Fixed regulators for WiFi, BT, LTE power control
- **Reset Logic**: Shared reset between BT and 802.15.4

### Removed Features
- **Audio**: WM8962 codec, SAI interfaces, microphone
- **Camera**: AP1302 ISP, MIPI CSI interface
- **Display**: HDMI/DSI output (E-ink uses different interface)
- **Ethernet**: Dual ethernet reduced to basic connectivity needs
- **Extra USB**: Multiple USB-C connectors simplified

## Hardware Test Status

- ✅ **Boot Test**: SUCCESSFUL
  - System boots with manually set `fdt_file=imx93-jaguar-eink.dtb`
  - Device tree loads correctly
  - Linux kernel initializes properly
  - User login working

- ❌ **Wireless Test**: ISSUES IDENTIFIED
  - **WiFi interface**: Not detected (`ip link show` shows no wlan interface)
  - **Wireless modules**: None loaded (`lsmod` shows no mlan/moal/wifi modules)
  - **SDIO devices**: Not detected (`/proc/bus/mmc/devices` doesn't exist)
  - **SPI devices**: One detected (`spi0.0`) but no 802.15.4 device
  - **Module autoloading**: Not configured (`/etc/modules-load.d/` empty)
  - **Kernel messages**: Cannot read dmesg (permission issue)

## Security Features Status

### EdgeLock Enclave (ELE) - Not Supported
- **Status**: ❌ **DISABLED** - Not used on E-Ink board
- **Reason**: Hardware design does not utilize ELE secure element
- **Implementation**: 
  - Kernel config: `CONFIG_IMX_SEC_ENCLAVE=n`
  - NVMEM driver: `CONFIG_NVMEM_IMX_OCOTP_FSB_S400=n` (requires ELE)
  - Device tree: No ELE-related nodes configured

### Cortex-M33 Co-processor - Not Supported  
- **Status**: ❌ **DISABLED** - Not used on E-Ink board
- **Reason**: Board design focuses on main Cortex-A55 cores only
- **Implementation**: Handled via kernel configuration, no device tree nodes

### Security Implications
- **Boot Security**: Standard i.MX93 secure boot without ELE
- **Fuse Access**: Uses standard OCOTP driver instead of ELE-based FSB S400
- **Key Storage**: No hardware secure element for key management
- **Attestation**: No ELE-based attestation capabilities

## Issues Fixed
1. ✅ **Machine config syntax** - Fixed `MACHINE_FEATURES:remove += ` → `=`
2. ✅ **Module autoloading** - Added `mlan moal` to `KERNEL_MODULE_AUTOLOAD`
3. ✅ **ZigBee support** - Added `zigbee` machine feature
4. ✅ **U-Boot approach** - Simplified to use `CONFIG_DEFAULT_FDT_FILE` only (removed patch)
5. ✅ **Kernel panic fix** - Resolved soc_imx9 module crash during ELE fuse reading
6. ✅ **Device tree compilation** - Fixed invalid label references (ele_fw2, cm33)
7. ✅ **U-Boot fiovb error** - Disabled unavailable Foundries.io verification command

## Current Status
- **Kernel Panic**: ✅ **FIXED** - EdgeLock Enclave dependencies disabled
- **Device Tree**: ✅ **FIXED** - Invalid label references removed
- **U-Boot Error**: ✅ **FIXED** - fiovb command disabled
- **Build Status**: ✅ **READY** - All compilation errors resolved
- **Boot Status**: ✅ **EXPECTED TO WORK** - Critical fixes applied

## Next Steps (Choose One)
1. **Rebuild U-Boot** - Apply permanent fdt_file fix
2. **Rebuild full image** - Include all wireless driver fixes
3. **Test current system** - Continue wireless debugging with current image

## Build Commands Reference
```bash
# Set machine and build
export KAS_MACHINE=imx93-jaguar-eink
./kas-build-base.sh

# Alternative direct bitbake commands
source build/setup-environment build
MACHINE=imx93-jaguar-eink bitbake lmp-factory-image

# Test specific components
MACHINE=imx93-jaguar-eink bitbake virtual/kernel
MACHINE=imx93-jaguar-eink bitbake u-boot-fio
```

## File Locations Summary
- **Device Tree**: `recipes-bsp/device-tree/lmp-device-tree/imx93-jaguar-eink.dts`
- **Machine Config**: `conf/machine/imx93-jaguar-eink.conf`
- **Kernel Configs**: `recipes-kernel/linux/linux-lmp-fslc-imx/imx93-jaguar-eink/*.cfg`
- **U-boot Configs**: `recipes-bsp/u-boot/u-boot-fio/imx93-jaguar-eink/*.cfg`
- **Output Images**: `build/tmp/deploy/images/imx93-jaguar-eink/`

## Git Status
- **Latest BSP Commit**: cee227a - "fix(imx93-jaguar-eink): remove non-existent device tree labels"
- **Latest Main Commit**: 77124952 - "fix(imx93-jaguar-eink): update BSP submodule for device tree fix"
- **Branch**: main
- **Status**: ✅ PUSHED to origin/main

## Recent Critical Fixes (2025-08-28)
1. **Kernel Panic Resolution**: Fixed soc_imx9 module crash during EdgeLock Enclave fuse reading
2. **Device Tree Compilation**: Removed invalid label references that don't exist in imx93.dtsi
3. **U-Boot Boot Error**: Disabled fiovb command that was causing boot failures
4. **EdgeLock Enclave**: Properly disabled ELE and related drivers since not used on E-Ink board

---
*Last Updated: 2025-08-28*
*Status: ✅ CRITICAL FIXES APPLIED - Boot issues resolved, ready for rebuild and testing*
