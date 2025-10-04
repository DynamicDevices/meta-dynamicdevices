# Custom Boot Files Directory

This directory contains known-good mfgtool bootloader files for board recovery and development testing.

## Contents

- **`imx-boot-mfgtool`** - Manufacturing bootloader (219KB)
- **`u-boot-mfgtool.itb`** - Manufacturing U-Boot (1.3MB)

## Purpose

These files serve as:
- **Recovery bootloaders** when cloud builds have broken mfgtools
- **Development testing** with known-working bootloader versions
- **Board-specific optimizations** for custom configurations

## Usage

### With Foundries.io Programming
```bash
# Use custom boot files for recovery
./scripts/fio-program-board.sh --factory sentai --machine imx8mm-jaguar-sentai --program --mfgfolder ./custom-boot-files
```

### With Local Build Programming
```bash
# Use custom boot files instead of locally built ones
./scripts/program-local-build.sh --machine imx8mm-jaguar-sentai --mfgfolder ./custom-boot-files
```

## When to Use

- **Broken cloud builds**: When latest Foundries.io builds have mfgtool issues
- **Board recovery**: When boards won't boot due to bootloader corruption
- **Development**: Testing new configurations without breaking working bootloaders
- **Debugging**: Isolating issues between bootloader and main image

## File Origins

These files come from known-working Foundries.io builds and should be updated periodically when stable builds are confirmed working.

## See Also

- [Board Programming Scripts](../README.md#board-programming--deployment)
- [Hardware Troubleshooting](../../wiki/Hardware-Troubleshooting.md)
