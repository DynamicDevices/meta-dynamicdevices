# TAS2563 ndev Mismatch Fix

## Problem Summary

The TAS2563 audio driver was failing with the error:
```
[6.743341] tasdevice-codec 1-004c: ndev(2) from Regbin and ndev(1)from DTS does not match
```

This error occurred because there was a mismatch between:
- **Regbin firmware**: Expected 2 devices (ndev=2)
- **Device tree configuration**: Configured for 1 device (`ti,channels = <1>`)

## Root Cause Analysis

### Hardware Configuration
The imx8mm-jaguar-sentai board has **only 1 TAS2563 device** at I2C address `0x4C`:
- Single audio amplifier configuration
- Device tree correctly configured with `ti,channels = <1>`

### Firmware Issue
The official Linux firmware `INT8866RCA2.bin` was designed for **dual-device configurations**:
- **Offset 23**: Contains `ndev = 2` (0x02)
- Driver validation failed when comparing regbin ndev vs DTS ndev

### Driver Validation Logic
```c
// From tasdevice-regbin.c:707-714
fw_hdr->ndev = buf[offset];  // offset = 23
if (fw_hdr->ndev != tas_dev->ndev) {
    dev_err(tas_dev->dev, "ndev(%u) from Regbin and ndev(%u)"
        "from DTS does not match\n", fw_hdr->ndev, tas_dev->ndev);
    ret = -1;
    goto out;
}
```

## Solution Implemented

### 1. Firmware Modification
Created a single-device version of the official firmware:

**Original**: `INT8866RCA2.bin` (ndev=2)
**Modified**: `INT8866RCA2-single.bin` (ndev=1)

**Changes Made**:
- **Offset 23**: Changed from `0x02` to `0x01` (ndev: 2 → 1)
- **Checksum**: Recalculated from `0xf82f91b2` to `0x45fcec6b`
- **Size**: Maintained at 1076 bytes
- **All other data**: Preserved unchanged

### 2. Recipe Update
Updated `kernel-module-tas2781_git.bb`:
```diff
- file://INT8866RCA2.bin \
+ file://INT8866RCA2-single.bin \

- install -m 644 ${WORKDIR}/INT8866RCA2.bin ${D}${nonarch_base_libdir}/firmware/tas2563-1amp-reg.bin
+ install -m 644 ${WORKDIR}/INT8866RCA2-single.bin ${D}${nonarch_base_libdir}/firmware/tas2563-1amp-reg.bin
```

## Technical Details

### Regbin Header Structure
```
Offset  Size  Field               Value (Modified)
------  ----  ------------------  ----------------
0-3     4     img_sz             0x00000434
4-7     4     checksum           0x45fcec6b (updated)
8-11    4     binary_version     0x00000105
12-15   4     drv_fw_version     0x00000101
16-19   4     timestamp          0x6570dcfe
20      1     plat_type          0x01
21      1     dev_family         0x00
22      1     reserve            0x00
23      1     ndev               0x01 (changed from 0x02)
```

### Checksum Calculation
```python
# Checksum covers all data after the first 8 bytes (size + checksum)
payload = data[8:]
new_checksum = zlib.crc32(payload) & 0xffffffff
```

## Verification

### Expected Results
After applying this fix, the driver should:
1. ✅ Successfully load the regbin firmware
2. ✅ Match ndev between firmware (1) and DTS (1)
3. ✅ Initialize the TAS2563 codec properly
4. ✅ No longer show the ndev mismatch error

### Testing Commands
```bash
# Check driver initialization
dmesg | grep tas2563

# Verify firmware loading
ls -la /lib/firmware/tas2563-*

# Check ALSA mixer controls
amixer -c Audio controls | grep -i tas
```

## Files Modified
- `meta-dynamicdevices-bsp/recipes-kernel/kernel-modules/kernel-module-tas2781_git.bb`
- Added: `INT8866RCA2-single.bin` (modified firmware)
- Removed: `INT8866RCA2.bin` (original dual-device firmware)

## References
- Official Linux firmware: https://gitlab.com/kernel-firmware/linux-firmware/-/tree/main/ti/tas2563
- TAS2781 driver source: `tas2781-linux-driver/src/tasdevice-regbin.c`
- Device tree binding: `tas2781-linux-driver/ti,tas2781.yaml`
