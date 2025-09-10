# TAS2563 Audio Driver Firmware Fix

## Problem Summary

The TAS2563 audio driver was using incorrect firmware binary files. The recipe was incorrectly using `48khzEchoSlot0.bin` for both the DSP firmware (`tas2563_uCDSP.bin`) and the register configuration binary (`tas2563-1amp-reg.bin`). This caused the firmware binary downloading to the codec to be wrong.

## Root Cause Analysis

Based on the TI integration PDF documentation and driver source code analysis:

1. **Two Different Firmware Types Required**:
   - **DSP Firmware** (`tas2563_uCDSP.bin`): For echo reference and DSP functionality
   - **Register Configuration Binary** (`tas2563-1amp-reg.bin`): For device initialization and configuration

2. **Binary Format Requirements**:
   - The driver expects regbin files in a specific binary format with:
     - Image size (4 bytes, big-endian)
     - Checksum (4 bytes, big-endian)
     - Binary version number (4 bytes, big-endian, must be >= 0x103)
     - Configuration data in structured format

3. **Previous Issue**:
   - Both firmware files were using the same `48khzEchoSlot0.bin` file
   - This file was not in the proper regbin format expected by the driver
   - The driver would fail to parse the configuration data correctly

## Solution Implemented

### 1. Created Binary Conversion Tool

Created `convert_json_to_regbin.py` that:
- Parses the TAS2563 JSON configuration file
- Converts it to the proper binary format expected by the driver
- Generates correct header with size, checksum, and version information
- Structures configuration data according to driver expectations

### 2. Updated Recipe Configuration

Modified `kernel-module-tas2781_git.bb` to:
- Add the conversion script as a source file
- Generate the proper regbin binary during compilation
- Install both firmware types correctly:
  - `tas2563_uCDSP.bin`: DSP firmware (unchanged)
  - `tas2563-1amp-reg.bin`: Properly generated regbin file
- Added Python3 native dependency for build-time conversion

### 3. Firmware File Mapping

| Firmware File | Purpose | Source | Format |
|---------------|---------|---------|---------|
| `tas2563_uCDSP.bin` | DSP/Echo Reference | `48khzEchoSlot0.bin` | Binary DSP firmware |
| `tas2563-1amp-reg.bin` | Register Configuration | Generated from JSON | Structured regbin format |

## Technical Details

### Binary Format Structure

The generated regbin file follows this structure:
```
Offset | Size | Field | Value
-------|------|-------|-------
0x00   | 4    | Image Size | Total file size (big-endian)
0x04   | 4    | Checksum | CRC32 of data after header (big-endian)
0x08   | 4    | Version | 0x105 (version 1.5)
0x0C   | 4    | Reserved | 0x00000000
0x10   | 4    | Config Count | Number of configurations
0x14   | 4    | Device Count | Number of devices (1)
0x18   | 4    | Amp Type | Amplifier type (0x03 for TAS2562/2563)
...    | ...  | Config Data | Structured configuration blocks
```

### Configuration Data Structure

Each configuration contains:
- Configuration name (64 bytes, null-terminated)
- Number of blocks
- Block data with commands (book, page, register, mask, data, delay)

## Files Modified

1. **`meta-dynamicdevices-bsp/recipes-kernel/kernel-modules/kernel-module-tas2781_git.bb`**
   - Added conversion script to SRC_URI
   - Added Python3 native dependency
   - Added compilation step to generate regbin binary
   - Updated installation to use correct firmware files

2. **`meta-dynamicdevices-bsp/recipes-kernel/kernel-modules/kernel-module-tas2781/convert_json_to_regbin.py`**
   - New Python script for JSON to regbin conversion
   - Handles TAS2563 configuration format
   - Generates driver-compatible binary format

## Testing Instructions

### 1. Build Verification
```bash
# Build the updated recipe
./scripts/kas-shell-base.sh -c 'MACHINE=imx8mm-jaguar-sentai bitbake kernel-module-tas2781'
```

### 2. Runtime Verification

After deploying to target:

```bash
# Check if firmware files are installed
ls -la /lib/firmware/tas2563*

# Check driver loading
dmesg | grep -i tas2563
dmesg | grep -i regbin

# Verify audio device registration
cat /proc/asound/cards
ls /sys/bus/i2c/devices/*/tas*

# Test regbin loading (if driver provides debug nodes)
cat /sys/bus/i2c/devices/2-004c/regbininfo_list
```

### 3. Expected Results

- **Firmware files present**: Both `tas2563_uCDSP.bin` and `tas2563-1amp-reg.bin` should exist
- **Driver messages**: Should show successful regbin loading without format errors
- **Audio device**: TAS2563 audio device should be properly registered
- **Configuration**: Driver should be able to parse and apply register configurations

## Benefits

1. **Correct Firmware Loading**: Driver now receives properly formatted regbin data
2. **Proper Device Initialization**: Register configurations can be applied correctly
3. **Maintainable Solution**: JSON-based configuration is easier to modify than binary files
4. **Build-time Generation**: Firmware is generated during build, ensuring consistency
5. **Documentation**: Clear separation between DSP firmware and register configuration

## Future Considerations

1. **DSP Firmware**: The current DSP firmware (`48khzEchoSlot0.bin`) should be validated for TAS2563 compatibility
2. **Configuration Variants**: Additional JSON configurations can be easily added for different use cases
3. **Tool Integration**: The conversion tool could be integrated into TI's official toolchain
4. **Validation**: Consider adding checksum validation during runtime loading

## References

- TI "Guideline for Integrated SmartAMP Linux driver" PDF
- TAS2781 Linux driver source code (`tasdevice-regbin.c`)
- TAS2563 JSON configuration format specification
