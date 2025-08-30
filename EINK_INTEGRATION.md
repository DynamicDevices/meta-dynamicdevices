# EL133UF1 E-Ink Display Integration Guide

## Overview

This document describes the integration of the EL133UF1 e-ink display driver into the Dynamic Devices Yocto build system.

**⚠️ IMPORTANT LICENSING NOTICE:**
- This software is received under NDA from E Ink Holdings Inc.
- The current MIT license may need to be changed to COMMERCIAL or PROPRIETARY
- Review licensing requirements before distribution or production use
- Consult legal team regarding appropriate license terms for commercial products

## Files Added

### 1. Recipe Files
- **`recipes-graphics/eink-spectra6/eink-spectra6_1.0.bb`**
  - Main BitBake recipe for the e-ink driver
  - Builds from GitHub repository: https://github.com/DynamicDevices/eink-spectra6
  - Creates test and demo applications
  - Sets up udev rules and systemd services

### 2. Feature Files  
- **`meta-dynamicdevices-distro/recipes-samples/images/lmp-feature-eink-spectra6.inc`**
  - Feature include file for e-ink display support
  - Adds driver and debugging tools to the image
  - Ensures required kernel modules are included

### 3. Image Integration
- **Modified `meta-dynamicdevices-distro/recipes-samples/images/lmp-factory-image.bb`**
  - Added automatic inclusion of e-ink driver for `imx93-jaguar-eink` machine
  - Uses conditional require based on MACHINE variable

### 4. Test Script
- **`scripts/test-eink-recipe.sh`**
  - Automated testing script for recipe validation
  - Tests parsing, dependencies, and source fetching

## Usage

### Building the Complete Image with E-Ink Support

```bash
# Build the full factory image (includes e-ink driver automatically for imx93-jaguar-eink)
KAS_MACHINE=imx93-jaguar-eink ./scripts/kas-build-profiling.sh
```

### Building Just the E-Ink Driver

```bash
# Build only the e-ink driver package
KAS_MACHINE=imx93-jaguar-eink kas shell kas/lmp-dynamicdevices.yml -c "bitbake eink-spectra6"
```

### Testing the Recipe

```bash
# Run automated tests
./scripts/test-eink-recipe.sh
```

## What Gets Installed

When the `imx93-jaguar-eink` machine is built, the following will be included:

### Applications
- **`el133uf1_test`** - Comprehensive test application
- **`el133uf1_demo`** - User-friendly demo application

### Libraries
- **`libel133uf1.so`** - Shared library for application development
- **`libel133uf1.a`** - Static library for embedded applications

### System Integration
- **udev rules** - Automatic SPI device permissions
- **systemd service** - Optional demo service (disabled by default)
- **GPIO group setup** - Proper permissions for GPIO access

### Development Tools
- **spitools** - SPI debugging utilities
- **i2c-tools** - I2C debugging utilities  
- **devmem2** - Memory debugging tool

### Kernel Modules
- **spi-dev** - SPI userspace interface
- **gpio-sysfs** - GPIO sysfs interface

## Hardware Configuration

The driver expects the following default GPIO configuration:
- **Reset GPIO**: 8 (configurable)
- **Busy GPIO**: 7 (configurable)
- **CS0 GPIO**: 0 (configurable)
- **CS1 GPIO**: 1 (configurable)
- **SPI Device**: `/dev/spidev1.0` (configurable)

## Testing on Target

After flashing the image to your `imx93-jaguar-eink` board:

### 1. Basic Communication Test
```bash
# Test SPI communication (will fail gracefully if no hardware)
el133uf1_test --test-spi
```

### 2. Hardware Status Check
```bash
# Read controller status (requires actual hardware)
el133uf1_test --test-status -v
```

### 3. Display Test
```bash
# Display white screen (requires actual hardware)
el133uf1_demo white
```

### 4. Custom Configuration
```bash
# Use different GPIO pins or SPI device
el133uf1_demo -d /dev/spidev0.0 -r 10 -b 11 white
```

## Development Workflow

### Making Changes to the Driver

1. **Update the source code** in the GitHub repository
2. **Push changes** to the main branch
3. **Rebuild** the recipe (it uses AUTOREV so will pick up latest changes):
   ```bash
   KAS_MACHINE=imx93-jaguar-eink kas shell kas/lmp-dynamicdevices.yml -c "bitbake -c cleanall eink-spectra6 && bitbake eink-spectra6"
   ```

### Using devtool for Development

If you want to modify the driver locally:

```bash
# Set up development workspace
KAS_MACHINE=imx93-jaguar-eink kas shell kas/lmp-dynamicdevices.yml -c "devtool modify eink-spectra6"

# Make changes in workspace/sources/eink-spectra6/

# Build and test
KAS_MACHINE=imx93-jaguar-eink kas shell kas/lmp-dynamicdevices.yml -c "devtool build eink-spectra6"

# Deploy to target (if using devtool deploy)
# devtool deploy-target eink-spectra6 root@<target-ip>

# Finish development and update recipe
# devtool finish eink-spectra6 meta-dynamicdevices
```

## Licensing Considerations

### Current Status
- Software received under NDA from E Ink Holdings Inc.
- Current MIT license may be placeholder/temporary
- **Action Required**: Review and update license before production

### License Options
1. **COMMERCIAL**: For commercial products with proper licensing agreement
2. **PROPRIETARY**: Most restrictive, suitable for NDA-protected code
3. **Current MIT**: May not reflect actual licensing terms

### Files to Review
- `LICENSE_NOTES.md` - Detailed licensing considerations
- `PROPRIETARY_LICENSE_EXAMPLE.bb` - Example proprietary recipe configuration

## Troubleshooting

### Recipe Not Found
- Ensure you're using `KAS_MACHINE=imx93-jaguar-eink`
- Check that the recipe file exists in `recipes-graphics/eink-spectra6/`

### Build Failures
- Check network connectivity for GitHub access
- Verify LICENSE checksum matches the actual file
- Ensure libgpiod is available in your build environment

### Runtime Issues
- Check SPI device permissions: `ls -la /dev/spidev*`
- Verify GPIO exports: `ls /sys/class/gpio/`
- Check kernel modules: `lsmod | grep spi`

### Licensing Issues
- Review NDA terms before distribution
- Consult legal team for appropriate license
- Update recipe when license is finalized

## Integration Notes

- The driver is **automatically included** only for `imx93-jaguar-eink` machine
- For other machines, you would need to add the feature manually or modify the conditional logic
- The recipe uses `AUTOREV` to always fetch the latest code from GitHub
- All GPIO numbers and SPI devices are configurable at runtime via command-line options

## Next Steps

1. **Test the recipe** with `./scripts/test-eink-recipe.sh`
2. **Build the image** with the e-ink driver included
3. **Flash and test** on actual hardware
4. **Customize GPIO mappings** as needed for your hardware
5. **Develop applications** using the provided library and examples
