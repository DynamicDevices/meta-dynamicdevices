# Scripts Directory

This directory contains utility scripts for building, testing, and managing the meta-dynamicdevices BSP layer.

## Download Scripts

### `fio-program-board.sh`
Downloads Foundries.io target builds and programs Dynamic Devices boards.

**Features:**
- Interactive configuration setup for factory and machine defaults
- Comprehensive fioctl authentication checking
- Downloads all required programming artifacts (wic.gz, bootloaders, U-Boot images)
- Generates ready-to-use programming scripts
- Automatic board programming with `--program` flag
- Intelligent caching to avoid re-downloading existing files
- Comprehensive timing for performance tracking
- Support for all Dynamic Devices board types

**Usage:**
```bash
# First time setup (interactive configuration)
./scripts/fio-program-board.sh --configure

# Download and program board automatically
./scripts/fio-program-board.sh --program

# Download specific target and program
./scripts/fio-program-board.sh 1451 --program

# Download only (manual programming)
./scripts/fio-program-board.sh 1451

# Override factory and machine
./scripts/fio-program-board.sh --factory my-factory --machine imx8mm-jaguar-sentai 1451

# Force re-download
./scripts/fio-program-board.sh --factory my-factory --machine imx93-jaguar-eink 1451 --force

# List available targets
./scripts/fio-program-board.sh --factory my-factory --list-targets

# Show version
./scripts/fio-program-board.sh --version
```

**Requirements:**
- fioctl installed and authenticated (`fioctl login`)
- Access to Foundries.io factory
- Valid target number from CI builds
- sudo access for board programming (USB device access)

**Programming:**
The script can automatically program boards with `--program`, or you can manually program after download:
```bash
# Put board in download mode, connect USB, then:
sudo ./program-<machine>.sh --flash
```

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