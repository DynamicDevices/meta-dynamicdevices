# TAS2563 Official Firmware Integration

## Summary

Successfully replaced custom TAS2563 firmware files with official firmware binaries from the [Linux firmware repository](https://gitlab.com/kernel-firmware/linux-firmware/-/tree/main/ti/tas2563). This ensures compatibility, proper functionality, and alignment with upstream Linux kernel expectations.

## Problem Addressed

The TAS2563 audio driver was using custom/development firmware files that were not properly formatted or officially supported. This could lead to:
- Compatibility issues with different kernel versions
- Unpredictable behavior or firmware loading failures  
- Lack of official support and updates
- Non-standard firmware format causing driver parsing errors

## Solution Implemented

### 1. Official Firmware Files Identified

From the [Linux firmware repository](https://gitlab.com/kernel-firmware/linux-firmware/-/tree/main/ti/tas2563):

| Official File | Size | Purpose | Target Filename |
|---------------|------|---------|-----------------|
| `INT8866RCA2.bin` | 1,076 bytes | Register Configuration | `tas2563-1amp-reg.bin` |
| `TAS2XXX3870.bin` | 20,128 bytes | DSP Firmware | `tas2563-1amp-dsp.bin` |

### 2. Firmware Format Analysis

**INT8866RCA2.bin (Regbin Format)**:
```
Offset | Value | Description
-------|-------|-------------
0x00   | 0x00000434 | Image size (1076 bytes)
0x04   | 0xf82f91b2 | CRC32 checksum  
0x08   | 0x00000105 | Binary version (1.5)
0x0C   | 0x00000101 | Configuration data
```

**TAS2XXX3870.bin (DSP Format)**:
```
Offset | Value | Description  
-------|-------|-------------
0x00   | 0x35353532 | DSP firmware header
0x04   | 0x00004ea0 | Firmware size info
0x08   | 0x112f088e | DSP version/checksum
```

### 3. Driver Filename Expectations

The TAS2781 driver constructs firmware filenames dynamically:

```c
// Register configuration firmware
scnprintf(tas_priv->regbin_binaryname, 64, "%s-%uamp-reg.bin", 
          tas_priv->dev_name, tas_priv->ndev);

// DSP firmware  
scnprintf(tas_dev->dsp_binaryname, 64, "%s-%uamp-dsp.bin",
          tas_dev->dev_name, tas_dev->ndev);
```

For TAS2563 with 1 amplifier:
- **Regbin**: `tas2563-1amp-reg.bin`
- **DSP**: `tas2563-1amp-dsp.bin`

## Files Modified

### Updated Recipe: `kernel-module-tas2781_git.bb`

**Before**:
```bitbake
SRC_URI = "git://... \
           file://48khzEchoSlot0.bin \
           file://tas2563-1amp-reg.json \
           file://convert_json_to_regbin.py \
           ..."

do_compile:append() {
  python3 ${WORKDIR}/convert_json_to_regbin.py ...
}

do_install:append() {
  install -m 644 ${WORKDIR}/48khzEchoSlot0.bin ${D}${nonarch_base_libdir}/firmware/tas2563_uCDSP.bin
  install -m 644 ${WORKDIR}/tas2563-1amp-reg.bin ${D}${nonarch_base_libdir}/firmware/tas2563-1amp-reg.bin
}
```

**After**:
```bitbake
SRC_URI = "git://... \
           file://INT8866RCA2.bin \
           file://TAS2XXX3870.bin \
           ..."

do_install:append() {
  install -d ${D}${nonarch_base_libdir}/firmware
  # Install official TAS2563 regbin firmware from Linux firmware repository
  install -m 644 ${WORKDIR}/INT8866RCA2.bin ${D}${nonarch_base_libdir}/firmware/tas2563-1amp-reg.bin
  # Install official TAS2563 DSP firmware from Linux firmware repository  
  install -m 644 ${WORKDIR}/TAS2XXX3870.bin ${D}${nonarch_base_libdir}/firmware/tas2563-1amp-dsp.bin
}
```

### Removed Files

- `48khzEchoSlot0.bin` - Custom DSP firmware
- `tas2563-1amp-reg.json` - JSON configuration  
- `convert_json_to_regbin.py` - Custom conversion script
- Generated `tas2563-1amp-reg.bin` - Custom regbin file

### Added Files

- `INT8866RCA2.bin` - Official regbin firmware from Linux firmware repository
- `TAS2XXX3870.bin` - Official DSP firmware from Linux firmware repository

## Technical Benefits

### 1. **Official Support**
- Uses firmware files maintained by the Linux kernel community
- Guaranteed compatibility with upstream TAS2781 driver
- Regular updates and bug fixes through official channels

### 2. **Proper Format Compliance**
- **Regbin file**: Correct header structure with proper size, checksum, and version
- **DSP firmware**: Standard format expected by the driver
- No custom parsing or conversion required

### 3. **Simplified Build Process**
- Removed Python dependency for build-time conversion
- Eliminated custom tooling and scripts
- Faster build times without conversion step

### 4. **Maintainability**
- No custom firmware generation to maintain
- Updates come automatically with Linux firmware package updates
- Reduced technical debt and complexity

## Verification Steps

### 1. Build Verification
```bash
# Build the updated recipe
./scripts/kas-shell-base.sh -c 'MACHINE=imx8mm-jaguar-sentai bitbake kernel-module-tas2781'
```

### 2. Runtime Verification
```bash
# Check firmware installation
ls -la /lib/firmware/tas2563-*

# Expected output:
# /lib/firmware/tas2563-1amp-reg.bin (1076 bytes)
# /lib/firmware/tas2563-1amp-dsp.bin (20128 bytes)

# Check driver loading
dmesg | grep -i tas2563
dmesg | grep -i "regbin_ready"
dmesg | grep -i "dspfw_ready"

# Verify audio device registration  
cat /proc/asound/cards
ls /sys/bus/i2c/devices/*/tas*
```

### 3. Expected Driver Messages
```
tas2563 2-004c: tasdev: regbin_ready start
tas2563 2-004c: tasdev: regbin_ready: firmware tas2563-1amp-reg.bin loaded successfully
tas2563 2-004c: tasdev: dspfw_ready: firmware tas2563-1amp-dsp.bin loaded successfully
```

## Firmware Source Information

**Repository**: [Linux Firmware - TAS2563](https://gitlab.com/kernel-firmware/linux-firmware/-/tree/main/ti/tas2563)

**Files Downloaded**:
- `INT8866RCA2.bin` - Register configuration firmware
- `TAS2XXX3870.bin` - DSP firmware

**License**: These firmware files are distributed under the Linux firmware license terms and are part of the official Linux kernel firmware collection.

## Future Considerations

### 1. **Firmware Updates**
- Monitor Linux firmware repository for TAS2563 firmware updates
- Consider automated update mechanism in CI/CD pipeline
- Test new firmware versions before deployment

### 2. **Multi-Amplifier Support**
- Current setup supports single amplifier (`1amp`)
- For multi-amplifier configurations, additional firmware files may be needed:
  - `tas2563-2amp-reg.bin` / `tas2563-2amp-dsp.bin`
  - `tas2563-4amp-reg.bin` / `tas2563-4amp-dsp.bin`

### 3. **Calibration Data**
- Driver also supports calibration files: `tas2563-0x4c-cal.bin`
- These are generated during factory calibration process
- Consider integration with factory calibration workflow

## References

- [Linux Firmware Repository - TAS2563](https://gitlab.com/kernel-firmware/linux-firmware/-/tree/main/ti/tas2563)
- TAS2781 Linux Driver Source Code (`tasdevice-codec.c`, `tasdevice-regbin.c`)
- TI TAS2563 Integration Documentation
- Linux Kernel Firmware Loading Documentation
