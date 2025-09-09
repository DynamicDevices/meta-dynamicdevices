# EdgeLock Enclave (ELE) Testing Guide

## Overview

This document describes the EdgeLock Enclave testing capabilities available for the i.MX93 Jaguar E-Ink board.

**⚠️ IMPORTANT: ELE testing tools are only included in development builds and should never be enabled in production images.**

## Development vs Production Builds

### Development Builds (ELE Testing Enabled)
- **Trigger**: `DEV_MODE=1` or `IMAGE_FEATURES` contains `debug-tweaks`
- **Includes**: ELE test suite, debug commands, development tools
- **U-Boot**: Enhanced ELE commands (`ele`, `ahab`, `fuse`, `mbox`)
- **Linux**: ELE test applications and utilities

### Production Builds (ELE Testing Disabled)
- **Trigger**: `DEV_MODE=0` or no `debug-tweaks` in `IMAGE_FEATURES`
- **Includes**: Only essential ELE drivers and functionality
- **U-Boot**: Basic ELE support without debug commands
- **Linux**: ELE drivers only, no test applications

## Building with ELE Testing

### Development Image with ELE Testing
```bash
# Method 1: Using DEV_MODE environment variable
DEV_MODE=1 KAS_MACHINE=imx93-jaguar-eink ./scripts/kas-build-base.sh

# Method 2: Using IMAGE_FEATURES (automatically set by DEV_MODE=1)
KAS_MACHINE=imx93-jaguar-eink ./scripts/kas-build-base.sh
# (DEV_MODE=1 is set by default in development configurations)
```

### Production Image (No ELE Testing)
```bash
# Production build without ELE testing tools
DEV_MODE=0 KAS_MACHINE=imx93-jaguar-eink ./scripts/kas-build-base.sh
```

### U-Boot Only with ELE Commands
```bash
# Build U-Boot with ELE debug commands (development only)
./scripts/build-uboot-ele.sh
```

## Available ELE Testing Tools

### Development Builds Include:

#### Linux Applications
- **`simple-ele-test`** - Hardware detection and basic testing
- **`run-ele-tests`** - Comprehensive test runner
- **`ele_hsm_test`** - NXP ELE HSM test (if available)
- **`ele_hsm_perf_test`** - NXP ELE performance test (if available)

#### U-Boot Commands (Development Only)
- **`ele info`** - ELE information and status
- **`ele ping`** - Test ELE communication
- **`ele version`** - ELE firmware version
- **`ahab status`** - Secure boot chain status
- **`fuse read`** - OTP fuse access
- **`mbox list`** - Mailbox communication test

### Production Builds Include:
- **ELE kernel drivers** - Essential functionality only
- **ELE device tree** - Hardware support
- **Basic ELE support** - No debug tools or test applications

## Testing ELE Functionality

### On Development Builds
```bash
# Run comprehensive ELE tests
run-ele-tests

# Run specific tests
simple-ele-test all
simple-ele-test status
simple-ele-test mailbox

# Check ELE status (existing script)
sudo /tmp/check_ele_status.sh
```

### In U-Boot (Development Builds)
```bash
# Test ELE communication
u-boot=> ele ping
u-boot=> ele info

# Check secure boot
u-boot=> ahab status

# Test mailbox
u-boot=> mbox list

# Read fuses
u-boot=> fuse read 0 0
```

## Security Considerations

### Why Development-Only?

1. **Security**: ELE test tools can expose sensitive information
2. **Attack Surface**: Debug commands increase potential attack vectors
3. **Production Hardening**: Production images should be minimal and secure
4. **Compliance**: Many security standards require debug features to be disabled in production

### Best Practices

1. **Never deploy development images to production**
2. **Always verify `DEV_MODE=0` for production builds**
3. **Use separate build pipelines for development and production**
4. **Regularly audit production images to ensure no debug tools are included**

## Troubleshooting

### ELE Tests Not Available
- **Check**: Is this a development build? (`DEV_MODE=1`)
- **Check**: Does the image have `debug-tweaks` feature?
- **Solution**: Rebuild with development configuration

### U-Boot ELE Commands Missing
- **Check**: Was U-Boot built with `DEV_MODE=1`?
- **Check**: Is `enable-ele-debug-commands.cfg` included?
- **Solution**: Rebuild U-Boot with development configuration

### ELE Hardware Not Detected
- **Check**: Run `simple-ele-test status` for hardware detection
- **Check**: Verify device tree ELE configuration
- **Check**: Ensure ELE drivers are loaded in kernel

## Configuration Files

### Development-Only Files
- `enable-ele-debug-commands.cfg` - U-Boot ELE debug commands
- `lmp-feature-ele-testing.inc` - ELE test suite for Linux
- `nxp-ele-test-suite` - ELE test applications

### Always Included Files
- `enable-ele-secure.cfg` - Basic ELE support
- ELE kernel drivers and device tree
- Essential ELE functionality

This ensures that ELE functionality is available for development and testing while maintaining security in production deployments.
