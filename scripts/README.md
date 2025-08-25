# Scripts Directory

This directory contains utility scripts for building, testing, and managing the meta-dynamicdevices BSP layer.

## Build Scripts

### `kas-build-base.sh`
Builds the base LmP image using KAS configuration.

### `kas-build-mfgtools.sh` 
Builds manufacturing/flashing tools image.

### `kas-shell-base.sh`
Opens an interactive shell in the KAS build environment.

## Board Programming

### `create-archive.sh`
Creates a compressed archive of built images for board programming.

### `program.sh`
Programs a board using UUU (Universal Update Utility).

## Testing & Validation

### `test-devicetree.sh`
Tests device tree compilation and validation.

## Usage Examples

### Complete Build and Program Workflow
```bash
# 1. Set target machine
export MACHINE=imx93-jaguar-eink

# 2. Build image
./scripts/kas-build-base.sh

# 3. Create programming archive  
./scripts/create-archive.sh

# 4. Program board (with board in download mode)
./scripts/program.sh
```