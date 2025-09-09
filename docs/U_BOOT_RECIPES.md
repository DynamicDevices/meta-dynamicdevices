# U-Boot Recipe Architecture for Dynamic Devices

## Overview

Dynamic Devices uses three different U-Boot recipes for different build purposes. Understanding this architecture is critical for applying optimizations correctly.

## Recipe Types

### 1. **Production & Development U-Boot** (`u-boot-fio`)

**Recipe**: `meta-dynamicdevices-bsp/recipes-bsp/u-boot/u-boot-fio_%.bbappend`

**Purpose**: 
- Main U-Boot binary that runs on the board after programming
- Used by both local KAS builds AND Foundries.io cloud builds

**Used By**:
- Local development: `kas build kas/lmp-dynamicdevices.yml`
- Foundries.io production builds (cloud)
- Runtime operation on programmed boards

**Optimizations Applied**:
- ✅ Ethernet removal (`disable-ethernet.cfg`)
- ✅ Boot delay reduction (`CONFIG_BOOTDELAY=1`)
- ✅ ELE commands (`enable-ele-secure.cfg`, `enable-ele-debug-commands.cfg`)
- ✅ Hardware-specific configs (I2C, SPI, etc.)

**Key Insight**: 🎉 **Boot optimizations automatically apply to BOTH local and production builds!**

### 2. **Manufacturing U-Boot** (`u-boot-fio-mfgtool`)

**Recipe**: `meta-dynamicdevices-bsp/recipes-bsp/u-boot/u-boot-fio-mfgtool_%.bbappend`

**Purpose**:
- Special U-Boot used only during board programming with UUU
- Temporary bootloader for manufacturing process

**Used By**:
- UUU board programming (`./scripts/fio-program-board.sh`)
- Manufacturing and initial board setup

**Special Configuration**:
- SE050 disabled (`disable-se050.cfg`) to prevent programming errors
- Minimal configuration for compatibility

**Optimizations**: ❌ **Not needed** - brief usage during programming only

### 3. **Boot Scripts** (`u-boot-ostree-scr-fit`)

**Recipe**: `meta-dynamicdevices-bsp/recipes-bsp/u-boot/u-boot-ostree-scr-fit.bbappend`

**Purpose**:
- Provides boot command scripts (`boot.cmd`) for Foundries.io builds
- **Does NOT control U-Boot binary configuration**

**Used By**:
- Foundries.io cloud builds for OSTree boot logic
- Production runtime boot sequence

**Contains**:
- Boot command scripts only (not U-Boot config)
- Device-specific boot parameters
- OSTree integration commands

**Optimizations**:
- `setenv silent 1` for reduced boot output
- Optimized boot command sequences

## Critical Architecture Points

### **Foundries.io vs Local Builds**

| Aspect | Local Development | Foundries.io Production |
|--------|------------------|------------------------|
| **U-Boot Binary** | `u-boot-fio` | `u-boot-fio` (same!) |
| **Boot Scripts** | Basic | `u-boot-ostree-scr-fit` |
| **Optimizations** | ✅ Applied | ✅ Applied (automatic) |
| **Build System** | KAS local | Cloud build |

### **Key Discovery**

🎯 **Boot time optimizations in `u-boot-fio_%.bbappend` apply to BOTH local and Foundries.io builds automatically!**

- No separate optimization needed for production builds
- `u-boot-ostree-scr-fit` only provides boot scripts, not U-Boot configuration
- Same U-Boot binary recipe used across build systems

## Configuration Files

### **U-Boot Configuration Files** (applied to `u-boot-fio`)

```
meta-dynamicdevices-bsp/recipes-bsp/u-boot/u-boot-fio/imx93-jaguar-eink/
├── custom-dtb.cfg              # Device tree customization
├── enable-i2c.cfg              # I2C support
├── enable-spi.cfg              # SPI support  
├── enable-ele-secure.cfg       # ELE/secure boot (bootdelay=1)
├── enable-ele-debug-commands.cfg # ELE debug commands (DEV_MODE only)
├── disable-ethernet.cfg        # Remove Ethernet (boot optimization)
├── disable-unused-peripherals.cfg # Remove unused hardware
└── enable-cm33.cfg             # Cortex-M33 support
```

### **Boot Scripts** (applied to `u-boot-ostree-scr-fit`)

```
meta-dynamicdevices-bsp/recipes-bsp/u-boot/u-boot-ostree-scr-fit/imx93-jaguar-eink/
└── boot.cmd                    # Boot command script with 'setenv silent 1'
```

## Best Practices

### **When Optimizing Boot Time**

1. **Focus on `u-boot-fio`**: Main recipe for both local and production
2. **Test locally first**: Use `kas build` to validate changes
3. **Verify Foundries.io**: Changes automatically apply to cloud builds
4. **Skip mfgtool**: Manufacturing U-Boot doesn't need runtime optimizations
5. **Consider boot scripts**: `u-boot-ostree-scr-fit` for command-level optimizations

### **Configuration Strategy**

- **Hardware configs**: Apply to `u-boot-fio` (persistent across builds)
- **Boot commands**: Apply to `u-boot-ostree-scr-fit` (Foundries.io specific)
- **Development tools**: Use conditional includes (`DEV_MODE=1`)
- **Manufacturing**: Keep `u-boot-fio-mfgtool` minimal and compatible

## Validation

### **Local Testing**
```bash
export MACHINE=imx93-jaguar-eink
kas build kas/lmp-dynamicdevices.yml
# Test optimizations in local build
```

### **Production Validation**
```bash
./scripts/fio-program-board.sh --machine imx93-jaguar-eink --program
# Optimizations automatically included in Foundries.io build
```

---

**Last Updated**: 2025-01-15  
**Maintainer**: Dynamic Devices <info@dynamicdevices.co.uk>
