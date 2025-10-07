# PCF2131 RTC Driver Backport for Kernel 6.1

## Overview
This document describes the backport of PCF2131 RTC support to Linux kernel 6.1.70-lmp-standard for the imx93-jaguar-eink board.

## Problem Statement
The NXP PCF2131 RTC chip requires kernel 6.6+ for native support, but our current LMP kernel is based on 6.1.70. The PCF2131 device was being detected on I2C bus 2 at address 0x53 but could not bind to the rtc-pcf2127 driver because PCF2131 support was not included in the kernel 6.1 version of the driver.

## Hardware Configuration
- **Board**: imx93-jaguar-eink
- **RTC Chip**: NXP PCF2131 (ultra-low power: 600nA vs 100µA for internal RTC)
- **I2C Bus**: LPI2C3 (mapped as i2c-2 in Linux)
- **I2C Address**: 0x53
- **Interrupt**: GPIO4_IO22 (INTA# - alarm/wake functionality)

## Device Detection Status (Before Patch)
```bash
# Device was detected but driver binding failed
/sys/bus/i2c/devices/2-0053/name: pcf2131
/sys/bus/i2c/devices/2-0053/modalias: of:NrtcT(null)Cnxp,pcf2131
/sys/bus/i2c/devices/2-0053/driver: [No driver bound]
```

## Backport Implementation

### Patch File: `0007-rtc-pcf2127-add-support-for-PCF2131-RTC.patch`
This patch adds PCF2131 support to the existing rtc-pcf2127 driver by:

1. **Adding PCF2131 device type enum**
   ```c
   enum pcf2127_type {
       PCF2127,
       PCF2129,
       PCF21XX,
       PCF2131,  // New PCF2131 support
   };
   ```

2. **Adding PCF2131 compatible string**
   ```c
   static const struct of_device_id pcf2127_of_match[] = {
       // ... existing entries ...
       {
           .compatible = "nxp,pcf2131",
           .data = (void *)PCF2131
       },
   };
   ```

3. **Adding I2C device ID support**
   ```c
   static const struct i2c_device_id pcf2127_i2c_id[] = {
       // ... existing entries ...
       { "pcf2131", PCF2131 },
   };
   ```

4. **Adding SPI device ID support**
   ```c
   static const struct spi_device_id pcf2127_spi_id[] = {
       // ... existing entries ...
       { "pcf2131", PCF2131 },
   };
   ```

5. **Adding PCF2131 detection logic**
   ```c
   if (type == PCF2131) {
       pcf2127->is_pcf2131 = true;
       dev_info(dev, "PCF2131 RTC detected\n");
   }
   ```

### Kernel Configuration
The existing kernel configuration in `pcf2131-rtc.cfg` is already correct:
```bash
CONFIG_RTC_DRV_PCF2127=y  # This driver now supports PCF2131
```

### Build Integration
Added the patch to the imx93-jaguar-eink kernel build in `linux-lmp-fslc-imx_%.bbappend`:
```bitbake
SRC_URI:append:imx93-jaguar-eink = " \
    # ... other files ...
    file://0007-rtc-pcf2127-add-support-for-PCF2131-RTC.patch \
"
```

## Device Tree Configuration
The device tree configuration in `imx93-jaguar-eink.dts` is already correct:
```dts
&lpi2c3 {
    status = "okay";
    
    pcf2131: rtc@53 {
        compatible = "nxp,pcf2131";  // This will now be recognized
        reg = <0x53>;
        interrupt-parent = <&gpio4>;
        interrupts = <22 IRQ_TYPE_LEVEL_LOW>;
        wakeup-source;
        nxp,power-mode = <3>;  // Direct switching mode for low power
    };
};
```

## Expected Results After Patch
After applying this patch and rebuilding the kernel:

1. **Driver Binding**: The PCF2131 device should bind to the rtc-pcf2127 driver
2. **RTC Device**: `/dev/rtc0` or `/dev/rtc1` should be created
3. **System Integration**: The RTC should be available for system time synchronization
4. **Wake Functionality**: The RTC should be able to wake the system from suspend

## Testing Commands
After deploying the patched kernel:
```bash
# Check driver binding
ls -la /sys/bus/i2c/devices/2-0053/driver

# Check RTC devices
ls -la /dev/rtc*

# Test RTC functionality
hwclock --show
timedatectl status

# Check kernel messages
dmesg | grep -E "pcf2131|rtc"
```

## Power Benefits
The PCF2131 provides significant power savings over the internal i.MX93 BBNSM RTC:
- **PCF2131**: 600nA (ultra-low power)
- **Internal RTC**: ~100µA (166x higher consumption)
- **Battery Life**: Enables 5-year battery backup operation

## Compatibility Notes
- This backport is specific to kernel 6.1.70-lmp-standard
- The patch is designed to be minimally invasive and maintain compatibility with existing PCF2127/29 devices
- Future kernel upgrades to 6.6+ will include native PCF2131 support, making this patch unnecessary

## Files Modified
1. `meta-dynamicdevices-bsp/recipes-kernel/linux/linux-lmp-fslc-imx/0007-rtc-pcf2127-add-support-for-PCF2131-RTC.patch` (new)
2. `meta-dynamicdevices-bsp/recipes-kernel/linux/linux-lmp-fslc-imx_%.bbappend` (updated)
3. `docs/PCF2131_RTC_BACKPORT.md` (this documentation)

## Build and Deployment
To apply these changes:
```bash
# Commit the changes
cd meta-dynamicdevices-bsp
git add .
git commit -m "kernel: backport PCF2131 RTC support to kernel 6.1"
git push

# Trigger cloud build
cd ../..
git add meta-dynamicdevices-bsp
git commit -m "Update BSP layer with PCF2131 RTC backport"
git push
./scripts/force-build.sh
```
