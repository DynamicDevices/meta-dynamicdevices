# Foundries.io U-Boot Recipe Architecture

## CRITICAL UNDERSTANDING: Two Separate U-Boot Builds

Foundries.io uses **TWO completely separate U-Boot recipes** that build independently:

### 1. Production U-Boot Recipe
- **File**: `meta-dynamicdevices-bsp/recipes-bsp/u-boot/u-boot-fio_%.bbappend`
- **Purpose**: Main OS image bootloader
- **Used for**: Production firmware, normal boot process
- **Can include**: Full features, optimizations, security, RTC support, etc.
- **Output**: `imx-boot-imx93-jaguar-eink`, `u-boot-imx93-jaguar-eink.itb`

### 2. MFGTools U-Boot Recipe  
- **File**: `meta-dynamicdevices-bsp/recipes-bsp/u-boot/u-boot-fio-mfgtool_%.bbappend`
- **Purpose**: UUU programming bootstrap bootloader
- **Used for**: Board programming, flashing firmware
- **Must remain**: Minimal, functional, stable
- **Output**: `imx-boot-mfgtool` (in mfgtool-files package)

## Key Principles

### ⚠️ **CRITICAL**: Changes are Independent
- Changes to `u-boot-fio_%.bbappend` do **NOT** affect mfgtool builds
- Changes to `u-boot-fio-mfgtool_%.bbappend` do **NOT** affect production builds
- Each recipe has its own configuration files and patches

### 🎯 **Configuration Strategy**
- **Production builds**: Can have aggressive optimizations, full features
- **MFGTools builds**: Must remain minimal and functional for programming

### 🔧 **When Debugging Build Issues**
1. **Identify which build is failing**: Production or MFGTools?
2. **Check the correct recipe**: Don't modify the wrong one
3. **Apply fixes to the appropriate recipe**

## Example: ELE (EdgeLock Enclave) Configuration

### Problem
- **Production kernel** needs ELE enabled for proper boot
- **MFGTools bootstrap** breaks when ELE is enabled

### Solution
- **Production recipe** (`u-boot-fio_%.bbappend`): Enable ELE support
- **MFGTools recipe** (`u-boot-fio-mfgtool_%.bbappend`): Disable ELE support

```bash
# Production U-Boot (u-boot-fio_%.bbappend)
SRC_URI:append:imx93-jaguar-eink = " file://enable-ele.cfg"

# MFGTools U-Boot (u-boot-fio-mfgtool_%.bbappend)  
SRC_URI:append:imx93-jaguar-eink = " file://disable-ele-mfgtool.cfg"
```

## Common Mistakes

### ❌ **Wrong Recipe Modification**
- Modifying production recipe expecting it to fix mfgtool issues
- Adding mfgtool-specific configs to production recipe

### ❌ **Assuming Single Configuration**
- Thinking one configuration affects both builds
- Not understanding the separation of concerns

### ❌ **Debugging Wrong Build**
- Looking at production build logs when mfgtool is failing
- Applying production fixes to mfgtool problems

## Best Practices

### ✅ **Separate Concerns**
- Keep mfgtool configurations minimal and stable
- Allow production configurations to be feature-rich

### ✅ **Test Both Builds**
- Verify mfgtool bootloader works for programming
- Verify production bootloader works for normal operation

### ✅ **Document Changes**
- Clearly state which recipe is being modified
- Explain why the change is needed for that specific build

## File Locations

```
meta-dynamicdevices-bsp/recipes-bsp/u-boot/
├── u-boot-fio_%.bbappend                    # Production builds
├── u-boot-fio-mfgtool_%.bbappend           # MFGTools builds
├── u-boot-fio/                             # Production config files
│   └── imx93-jaguar-eink/
│       ├── enable-ele.cfg
│       ├── enable-i2c.cfg
│       └── ...
└── u-boot-fio-mfgtool/                     # MFGTools config files
    ├── disable-se050.cfg
    ├── disable-ele-mfgtool.cfg
    └── ...
```

## Summary

Understanding this **dual recipe architecture** is critical for:
- ✅ Successful board programming (working mfgtool bootloader)
- ✅ Successful production operation (feature-rich production bootloader)  
- ✅ Efficient debugging (targeting the right recipe)
- ✅ Proper configuration management (separation of concerns)

**Remember**: When in doubt, check which build is failing and modify the corresponding recipe!
