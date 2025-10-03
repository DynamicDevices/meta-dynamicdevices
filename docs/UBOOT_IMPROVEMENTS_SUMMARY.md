# U-Boot Improvements for imx93-jaguar-eink

## Overview

This document summarizes the U-Boot improvements implemented to resolve boot issues and optimize the boot process for the Dynamic Devices i.MX93 Jaguar E-Ink board.

## Issues Identified and Fixed

### 1. ❌ TCPC (Type-C Port Controller) Errors
**Problem:**
```
tcpc_init: Can't find device id=0x52
tcpc_init: Can't find device id=0x51  
tcpc_init: Can't find device id=0x50
setup_typec: tcpc portpd init failed, err=-19
```

**Root Cause:** U-Boot trying to initialize TCPC hardware not present on Jaguar E-Ink board

**Solution:** ✅ **ALREADY IMPLEMENTED**
- Configuration exists in `disable-unused-peripherals.cfg`
- `CONFIG_USB_TCPC=n` disables TCPC support
- Need to rebuild U-Boot to apply

### 2. ❌ PCA953x GPIO Expander Error
**Problem:**
```
pca953x gpio@22: Error reading output register
```

**Root Cause:** U-Boot trying to access GPIO expander not present on board

**Solution:** ✅ **ALREADY IMPLEMENTED**
- Configuration exists in `disable-unused-peripherals.cfg`
- `CONFIG_DM_PCA953X=n` disables PCA953x support
- Need to rebuild U-Boot to apply

### 3. ❌ Generic Board Model Display
**Problem:**
```
Model: NXP i.MX93 11X11 EVK board
```

**Root Cause:** U-Boot using generic EVK board identification

**Solution:** ✅ **NEW PATCH CREATED**
- Created `02-board-model-identification.patch`
- Adds board detection logic
- Will display: "Dynamic Devices i.MX93 Jaguar E-Ink board"

### 4. ❌ Environment Loading from <NULL>
**Problem:**
```
Loading Environment from <NULL>... OK
```

**Root Cause:** `CONFIG_ENV_IS_NOWHERE=y` in boot profiling configuration

**Solution:** ✅ **NEW CONFIG CREATED**
- Created `fix-environment-config.cfg`
- Uses proper MMC environment storage
- Eliminates the "<NULL>" message

## Files Created/Modified

### New Configuration Files
1. **`02-board-model-identification.patch`**
   - Adds proper board identification logic
   - Updates board name display and device tree selection

2. **`fix-environment-config.cfg`**
   - Fixes environment storage configuration
   - Uses MMC instead of "nowhere"

3. **`optimized-boot.cfg`**
   - Replaces problematic boot profiling config
   - Maintains fast boot while fixing issues

### Modified Files
1. **`u-boot-fio_%.bbappend`**
   - Updated to include all new configurations
   - Removed problematic boot profiling dependency

## Expected Results After Rebuild

### ✅ Clean Boot Output
```
U-Boot 2023.04+fio+gd5bf13df210 (Mar 06 2024 - 13:51:22 +0000)

CPU:   i.MX93(52) rev1.1 1700 MHz (running at 1692 MHz)
CPU:   Industrial temperature grade (-40C to 105C) at 40C
Reset cause: POR (0x1)
Board: Dynamic Devices i.MX93 Jaguar E-Ink board
DRAM:  2 GiB
I/TC: Reserved shared memory is enabled
I/TC: Dynamic shared memory is enabled
I/TC: Normal World virtualization support is disabled
I/TC: Asynchronous notifications are disabled
Core:  206 devices, 26 uclasses, devicetree: separate
MMC:   FSL_SDHC: 0, FSL_SDHC: 1
Loading Environment from MMC... OK
In:    serial
Out:   serial
Err:   serial
```

### Key Improvements
- ❌ **ELIMINATED:** TCPC error messages
- ❌ **ELIMINATED:** PCA953x error messages  
- ✅ **IMPROVED:** Proper board identification
- ✅ **FIXED:** Environment loading from MMC instead of <NULL>
- ✅ **OPTIMIZED:** Faster boot with reduced delays

## Rebuild Instructions

### Method 1: Using kas (Recommended)
```bash
cd /home/ajlennon/data_drive/dd/meta-dynamicdevices

# Clean and rebuild U-Boot
KAS_MACHINE=imx93-jaguar-eink kas shell kas/lmp-dynamicdevices.yml -c "bitbake -c cleanall u-boot-fio"
KAS_MACHINE=imx93-jaguar-eink kas shell kas/lmp-dynamicdevices.yml -c "bitbake u-boot-fio"
```

### Method 2: Direct BitBake (if kas has issues)
```bash
cd /home/ajlennon/data_drive/dd/meta-dynamicdevices/build
source layers/openembedded-core/oe-init-build-env .
export MACHINE=imx93-jaguar-eink
bitbake -c cleanall u-boot-fio
bitbake u-boot-fio
```

### Method 3: Using provided script
```bash
cd /home/ajlennon/data_drive/dd/meta-dynamicdevices
./rebuild-uboot.sh
```

## Deployment

After successful rebuild, the new U-Boot files will be located in:
```
build/tmp/deploy/images/imx93-jaguar-eink/
├── imx-boot-imx93-jaguar-eink
├── u-boot-imx93-jaguar-eink.bin
└── u-boot-imx93-jaguar-eink.itb
```

Copy these files to your programming directory and use with UUU for device programming.

## Configuration Summary

### U-Boot Recipe Changes
The `u-boot-fio_%.bbappend` now includes:
```bitbake
SRC_URI:append:imx93-jaguar-eink = " \
    file://custom-dtb.cfg \
    file://02-board-model-identification.patch \
    file://enable-i2c.cfg \
    file://enable-spi.cfg \
    file://enable-fiovb.cfg \
    file://disable-unused-peripherals.cfg \
    file://fix-environment-config.cfg \
    file://optimized-boot.cfg \
"
```

### Key Configuration Options Applied
- `CONFIG_USB_TCPC=n` - Eliminates TCPC errors
- `CONFIG_DM_PCA953X=n` - Eliminates PCA953x errors
- `CONFIG_ENV_IS_IN_MMC=y` - Proper environment storage
- `CONFIG_BOOTDELAY=2` - Reasonable boot delay
- Board identification patch - Proper board name display

## Verification

After programming the new U-Boot, verify the improvements by checking:
1. No TCPC error messages during boot
2. No PCA953x error messages during boot
3. Board displays as "Dynamic Devices i.MX93 Jaguar E-Ink board"
4. Environment loads from MMC (not <NULL>)
5. Faster overall boot time

## Troubleshooting

If issues persist after rebuild:
1. Verify all configuration files are present in the U-Boot recipe directory
2. Check that the machine is set correctly (`MACHINE=imx93-jaguar-eink`)
3. Ensure clean build was performed (`bitbake -c cleanall u-boot-fio`)
4. Verify the correct U-Boot binary is being programmed to the device

## Contact

For questions or issues with these improvements, contact:
- Alex J Lennon <ajlennon@dynamicdevices.co.uk>
- Dynamic Devices Ltd
