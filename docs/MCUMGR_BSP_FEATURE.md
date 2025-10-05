# MCUmgr BSP Feature Implementation

## Overview

This document describes the implementation of the MCUmgr BSP feature for the Dynamic Devices meta-dynamicdevices layer, specifically enabling MCUmgr support for the imx93-jaguar-eink machine with its MCXC143VFM power controller.

## Implementation Structure

### 1. BSP Layer Integration (`meta-dynamicdevices-bsp`)

#### Machine Feature Configuration
- **File**: `conf/machine/include/mcumgr.inc`
- **Purpose**: Defines the mcumgr machine feature and its dependencies
- **Key Components**:
  - Adds `mcumgr` to `MACHINE_FEATURES_BACKFILL_CONSIDERED`
  - Includes `mcumgr-simple` package when feature is enabled
  - Adds serial communication tools (screen, minicom)
  - Configures user permissions for serial device access

#### Recipe Implementation
- **Location**: `recipes-devtools/mcumgr/`
- **Files**:
  - `mcumgr_git.bb` - Full-featured recipe with Go toolchain
  - `mcumgr-simple_git.bb` - Simplified build (recommended)
  - `mcumgr-support.inc` - Include helper for easy integration
  - `README.md` - Complete documentation

#### Machine Configuration
- **File**: `conf/machine/imx93-jaguar-eink.conf`
- **Changes**:
  - Added `require conf/machine/include/mcumgr.inc`
  - Added `MACHINE_FEATURES:append:imx93-jaguar-eink = " mcumgr"`

#### Documentation
- **File**: `conf/machine-features/mcumgr.md`
- **Content**: Complete feature documentation with usage examples

### 2. Testing Infrastructure

#### Test Script
- **File**: `scripts/test-mcumgr-bsp.sh`
- **Purpose**: Validates BSP feature integration
- **Tests**:
  - Machine feature configuration
  - Recipe parsing
  - Package dependencies
  - Include file validation
  - Machine configuration verification

## Usage

### For Developers

1. **Enable the feature** (already done for imx93-jaguar-eink):
   ```bitbake
   MACHINE_FEATURES:append:your-machine = " mcumgr"
   ```

2. **Build the image**:
   ```bash
   export KAS_MACHINE=imx93-jaguar-eink
   kas build kas/lmp-dynamicdevices.yml
   ```

3. **Test the integration**:
   ```bash
   ./scripts/test-mcumgr-bsp.sh imx93-jaguar-eink
   ```

### For End Users

Once the image is built and deployed:

1. **Setup MCUmgr connection**:
   ```bash
   mcumgr-setup /dev/ttyUSB0 115200 serial1
   ```

2. **Manage Zephyr firmware**:
   ```bash
   mcumgr -c serial1 image list
   mcumgr -c serial1 image upload firmware.signed.bin
   mcumgr -c serial1 reset
   ```

## Integration Benefits

### 1. **Proper BSP Architecture**
- MCUmgr is now a proper machine feature
- Only enabled for machines that need it
- Follows Yocto best practices for BSP layers

### 2. **Automatic Dependencies**
- Serial communication tools included automatically
- User permissions configured correctly
- Development tools added for debug builds

### 3. **Clean Separation**
- Hardware-specific tools in BSP layer
- Machine-specific configuration
- Reusable across similar machines

### 4. **Documentation**
- Complete feature documentation
- Usage examples and troubleshooting
- Integration guides for developers

## Hardware Context

### Target Hardware
- **Main Processor**: i.MX93 (Linux/Yocto)
- **Microcontroller**: MCXC143VFM (Zephyr RTOS)
- **Communication**: UART/Serial at 115200 baud
- **Bootloader**: MCUboot with serial recovery

### Use Case
- **Power Management**: MCXC143VFM controls power systems
- **Firmware Updates**: MCUmgr enables remote updates
- **Development**: Tools for debugging and testing
- **Production**: Secure signed firmware deployment

## Future Extensions

### Additional Machines
The mcumgr feature can be easily added to other machines:
```bitbake
# In your-machine.conf
require conf/machine/include/mcumgr.inc
MACHINE_FEATURES:append:your-machine = " mcumgr"
```

### Transport Support
- **Bluetooth LE**: For wireless updates
- **UDP/Network**: For remote management
- **Multiple Devices**: Batch operations

### Integration Opportunities
- **Foundries.io OTA**: Integration with cloud updates
- **CI/CD Pipelines**: Automated testing and deployment
- **Fleet Management**: Multiple device coordination

## Validation

### Test Results
Run the test script to validate the implementation:
```bash
./scripts/test-mcumgr-bsp.sh imx93-jaguar-eink
```

Expected output:
- ✅ MCUmgr machine feature is enabled
- ✅ mcumgr-simple recipe parses successfully
- ✅ MCUmgr packages are included in machine dependencies
- ✅ Include file contains proper configuration
- ✅ Machine configuration includes mcumgr.inc
- ✅ Machine configuration enables mcumgr feature

### Build Verification
```bash
# Check if mcumgr is included in the image
kas shell kas/lmp-dynamicdevices.yml -c "export MACHINE=imx93-jaguar-eink && bitbake -e lmp-factory-image | grep mcumgr"
```

## Maintenance

### Recipe Updates
- Monitor mynewt-mcumgr-cli repository for updates
- Update SRCREV in recipe when new versions are available
- Test compatibility with Zephyr RTOS updates

### Documentation
- Keep machine feature documentation current
- Update examples based on user feedback
- Maintain compatibility matrix

## Security Considerations

### Firmware Signing
- Always use signed firmware images
- Manage signing keys securely
- Implement key rotation procedures

### Access Control
- Serial device permissions configured automatically
- Consider dedicated service accounts for production
- Implement proper authentication for remote access

---

**Implementation Date**: 2025-01-05  
**Target Machine**: imx93-jaguar-eink  
**Microcontroller**: MCXC143VFM  
**Status**: Complete and Ready for Testing
