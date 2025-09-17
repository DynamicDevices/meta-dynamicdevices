# Scripts Directory

This directory contains utility scripts for building, testing, managing, and automating the meta-dynamicdevices BSP layer development workflow.

## 📊 Script Summary

| Script | Category | Purpose | Key Features |
|--------|----------|---------|--------------|
| `fio-program-board.sh/.bat` | Board Programming | Foundries.io board programming | Interactive config, caching, timing |
| `program-local-build.sh` | Board Programming | Local build programming | UUU integration, custom boot files |
| `kas-build-base.sh` | Build System | Base LmP image builds | KAS container integration |
| `kas-shell-base.sh` | Build System | Interactive KAS shell | Development environment |
| `build-with-boot-profiling.sh` | Build System | Profiling-enabled builds | Boot optimization targeting |
| `boot-timing-suite.sh` | Performance | Complete boot analysis | Capture, analyze, compare |
| `serial-boot-logger.sh` | Performance | Serial boot capture | Real-time monitoring |
| `analyze-boot-logs.sh` | Performance | Boot log analysis | Timing breakdown, recommendations |
| `test-tas2563-mics.sh` | Audio Testing | TAS2563 microphone tests | Dual mic validation |
| `test-tas2563-sdout.sh` | Audio Testing | TAS2563 serial data output | Echo reference testing |
| `detect-audio-hardware.sh` | Audio Testing | Audio hardware detection | PDM vs TAS2563 detection |
| `eink-dual-cs-control.sh` | E-Ink Testing | Dual chip select control | CS0/CS1 independent control |
| `toggle-eink-cs.sh` | E-Ink Testing | Simple CS toggle | Display routing verification |
| `test-eink-cs-routing.sh` | E-Ink Testing | CS routing tests | Connectivity validation |
| `check_ele_status.sh` | Security | EdgeLock Enclave status | ELE driver verification |
| `generate-dummy-keys.sh` | Security | Development key generation | Local build signing keys |
| `validate-dummy-keys.sh` | Security | Key validation | Development key verification |
| `create-github-issue.sh` | Project Management | Issue creation | Automated GitHub issues |
| `cleanup-workflow-runs.sh` | CI/CD | Workflow cleanup | GitHub Actions maintenance |
| `prioritize-all-issues.sh` | Project Management | Issue prioritization | Automated priority labeling |
| `rdc-control.sh` | Hardware Control | Resource domain control | i.MX8MM RDC management |
| `validation/validate-layers.sh` | Quality Assurance | Yocto layer validation | Project compatibility |
| `validate-layers-local.sh` | Quality Assurance | Comprehensive yocto-check-layer validation | KAS-based local validation |

## 📋 Table of Contents

- [Board Programming & Deployment](#board-programming--deployment)
- [Build & Development](#build--development)
- [Testing & Validation](#testing--validation)
- [CI/CD & GitHub Management](#cicd--github-management)
- [Security & Keys](#security--keys)
- [Audio Hardware Testing](#audio-hardware-testing)
- [Utilities & Helpers](#utilities--helpers)

---

## 🔧 Board Programming & Deployment

### `fio-program-board.sh` / `fio-program-board.bat`
**Purpose:** Downloads Foundries.io target builds and programs Dynamic Devices boards.

**Features:**
- Interactive configuration setup for factory and machine defaults
- Comprehensive fioctl authentication checking
- Downloads all required programming artifacts (wic.gz, bootloaders, U-Boot images)
- Generates ready-to-use programming scripts
- Automatic board programming with `--program` flag
- Custom boot files support with `--mfgfolder` option
- Intelligent caching to avoid re-downloading existing files
- Comprehensive timing for download and programming performance tracking
- Support for all Dynamic Devices board types
- Cross-platform support (Linux/Windows)

**Usage:**
```bash
# First time setup (interactive configuration)
./scripts/fio-program-board.sh --configure

# Download and program board automatically
./scripts/fio-program-board.sh --program

# Download specific target and program
./scripts/fio-program-board.sh 1451 --program

# Override factory and machine
./scripts/fio-program-board.sh --factory my-factory --machine imx8mm-jaguar-sentai 1451

# Program imx8mm-jaguar-sentai with custom boot files (RECOMMENDED)
./scripts/fio-program-board.sh --factory sentai --machine imx8mm-jaguar-sentai --program --mfgfolder program

# Use custom boot files from relative path
./scripts/fio-program-board.sh --factory sentai --machine imx8mm-jaguar-sentai --program --mfgfolder ./custom-boot-files

# List available targets
./scripts/fio-program-board.sh --factory my-factory --list-targets
```

**Custom Boot Files (--mfgfolder option):**

The `--mfgfolder` option allows you to specify a custom directory containing `imx-boot-mfgtool` and `u-boot-mfgtool.itb` files. This is particularly useful for:

- **Board-specific optimizations**: Using custom bootloader configurations
- **Development testing**: Testing new bootloader versions
- **Recovery scenarios**: Using known-good bootloader files

**How it works:**
1. The script copies your custom boot files to the extracted mfgtool-files directory
2. The original UUU scripts run unchanged, but now use your custom files
3. Relative paths are resolved relative to your current working directory

**Example structure:**
```
program/                          # Custom boot files directory
├── imx-boot-mfgtool             # Custom manufacturing bootloader
├── u-boot-mfgtool.itb           # Custom manufacturing U-Boot
└── uuu                          # (Optional) UUU executable
```

### `program-local-build.sh`
**Purpose:** Programs a board using UUU (Universal Update Utility) with locally built images.

**Features:**
- Uses locally built mfgtool-files and UUU scripts
- Custom boot firmware support with `--mfgfolder` option
- Automatic file validation and linking
- Clean temporary file handling

**Usage:**
```bash
# Program board with locally built image
./scripts/program-local-build.sh --machine imx8mm-jaguar-sentai

# Use custom boot firmware files (files used directly, not copied)
./scripts/program-local-build.sh --machine imx8mm-jaguar-sentai --mfgfolder /path/to/custom/boot/files

# Use custom boot files from relative path
./scripts/program-local-build.sh --machine imx8mm-jaguar-sentai --mfgfolder ./custom-boot-files
```

**Custom Boot Files (--mfgfolder option):**

The `--mfgfolder` option allows you to specify a custom directory containing `imx-boot-mfgtool` and `u-boot-mfgtool.itb` files. This is particularly useful for:

- **Board-specific optimizations**: Using custom bootloader configurations
- **Development testing**: Testing new bootloader versions  
- **Recovery scenarios**: Using known-good bootloader files

**How it works:**
1. The script validates your custom folder contains the required files
2. Creates temporary symbolic links to your custom files with unique names
3. Generates a temporary UUU script that references these custom files
4. Runs UUU with the temporary script using your custom boot firmware
5. Cleans up all temporary files after programming completes

**Example structure:**
```
custom-boot-files/               # Custom boot files directory
├── imx-boot-mfgtool            # Custom manufacturing bootloader
└── u-boot-mfgtool.itb          # Custom manufacturing U-Boot
```

### `create-archive.sh`
**Purpose:** Creates a compressed archive (.tgz) of built images for distribution and board programming.

**Features:**
- Packages all necessary programming files
- Creates timestamped archives
- Includes programming scripts and documentation

---

## 🏗️ Build & Development

### `kas-build-base.sh`
**Purpose:** Builds the base LmP (Linux microPlatform) image using KAS configuration.

**Usage:**
```bash
# Build for default machine
./scripts/kas-build-base.sh

# Build for specific machine
MACHINE=imx93-jaguar-eink ./scripts/kas-build-base.sh
```

### `kas-build-base-enhanced.sh`
**Purpose:** Enhanced build script with additional features and optimizations.

### `kas-build-mfgtools.sh`
**Purpose:** Builds manufacturing/flashing tools image for board programming.

### `kas-build-profiling.sh`
**Purpose:** Builds images with profiling enabled for performance analysis.

### `kas-shell-base.sh`
**Purpose:** Opens an interactive shell in the KAS build environment for development and debugging.

**Usage:**
```bash
# Enter KAS shell environment
./scripts/kas-shell-base.sh

# Inside shell, you can run bitbake commands directly
bitbake core-image-minimal
```

### `build-with-boot-profiling.sh`
**Purpose:** Specialized build script with boot profiling enabled for Dynamic Devices boards.

**Features:**
- Targets 1-2 second boot time optimization
- Enables boot profiling instrumentation
- Generates boot performance reports

**Usage:**
```bash
# Build with profiling for default machine
./scripts/build-with-boot-profiling.sh

# Build for specific machine
./scripts/build-with-boot-profiling.sh imx93-jaguar-eink
```

---

## 🧪 Testing & Validation

### `test-devicetree.sh`
**Purpose:** Tests device tree compilation and validation for all supported machines.

### `test-eink-recipe.sh`
**Purpose:** Tests e-ink display functionality and recipe validation.

### `test-tas2563-mics.sh`
**Purpose:** Comprehensive test script for TAS2563 integrated microphone functionality.

**Features:**
- Tests dual microphone capture
- Validates audio quality and levels
- Supports quick, full, and debug test modes

**Usage:**
```bash
# Quick test
./scripts/test-tas2563-mics.sh quick

# Full comprehensive test
./scripts/test-tas2563-mics.sh full

# Debug mode with detailed output
./scripts/test-tas2563-mics.sh debug
```

### `test-tas2563-sdout.sh`
**Purpose:** Tests TAS2563 Serial Data Output functionality for echo reference and monitoring.

### `detect-audio-hardware.sh`
**Purpose:** Hardware detection script for dual audio configuration.

**Features:**
- Detects whether system has original PDM microphones or TAS2563 integrated microphones
- Sets environment variables for ALSA configuration selection
- Persistent configuration storage
- Runtime hardware switching support

### Validation Scripts (`validation/`)

#### `validate-layers.sh`
**Purpose:** Validates Yocto layer compatibility using official Yocto tools.

#### `validate-layers-local.sh`
**Purpose:** Comprehensive yocto-check-layer validation using KAS environment setup.

**Features:**
- Sets up proper Yocto environment with all dependencies using KAS
- Runs official `yocto-check-layer` tool for comprehensive validation
- Validates all meta-dynamicdevices layers (BSP, distro, main)
- Includes all required layer dependencies (meta-imx, meta-lmp, etc.)
- Provides detailed validation reports and logging
- Supports clean build option for fresh validation

**Usage:**
```bash
# Run validation with existing build
./scripts/validate-layers-local.sh

# Clean build and run validation
./scripts/validate-layers-local.sh --clean

# Show help
./scripts/validate-layers-local.sh --help
```

**Requirements:**
- KAS installed (`pip3 install kas`)
- Git access to required repositories
- Sufficient disk space for full Yocto environment

**Validation Coverage:**
- Layer structure and configuration syntax
- Recipe parsing and BitBake compatibility  
- Machine and distro compatibility testing
- Patch upstream status validation
- BitBake signature generation testing
- Collection name conflict detection

#### `pre-commit-hook.sh`
**Purpose:** Pre-commit validation hook for code quality and standards compliance.

---

## 🤖 CI/CD & GitHub Management

### `cleanup-workflow-runs.sh`
**Purpose:** Cleans up old GitHub Actions workflow runs to manage repository storage.

**Features:**
- Removes completed workflow runs older than specified days
- Preserves recent and failed runs for debugging
- Requires GitHub CLI authentication

### `cleanup-failed-runs.sh`
**Purpose:** Specifically cleans up failed CI/CD runs to reduce clutter.

### GitHub Issue Management Scripts

#### `create-github-issue.sh`
**Purpose:** Creates GitHub issues programmatically with proper labeling and formatting.

**Usage:**
```bash
./scripts/create-github-issue.sh "Issue Title" "Issue Body" "label1,label2"
```

#### `create-board-projects.sh`
**Purpose:** Creates GitHub project boards for organizing board-specific development tasks.

#### `create-identified-issues.sh` / `create-identified-issues-simple.sh`
**Purpose:** Batch creates GitHub issues from identified problems or TODO items.

#### `create-issues-from-review.sh`
**Purpose:** Creates issues from code review feedback and comments.

#### `create-specific-todo-issues.sh`
**Purpose:** Converts specific TODO comments in code to tracked GitHub issues.

### Issue Organization & Management

#### `add-additional-labels.sh`
**Purpose:** Adds additional labels to GitHub issues for better categorization.

#### `add-time-estimates.sh`
**Purpose:** Adds time estimate labels to GitHub issues for project planning.

#### `label-software-firmware-issues.sh`
**Purpose:** Automatically labels issues as software or firmware related.

#### `organize-issues-by-board.sh`
**Purpose:** Organizes GitHub issues by target board/hardware platform.

#### `prioritize-all-issues.sh`
**Purpose:** Applies priority labels to all issues based on predefined criteria.

#### `update-hardware-issues.sh`
**Purpose:** Updates hardware-related issues with current status and information.

---

## 🔐 Security & Keys

### `generate-dummy-keys.sh`
**Purpose:** Generates dummy signing keys for local development builds.

**⚠️ Important:** These are NOT production keys and should never be used for real devices.

**Features:**
- Generates OP-TEE signing keys
- Creates U-Boot signing keys
- Sets up local development key infrastructure

**Usage:**
```bash
./scripts/generate-dummy-keys.sh
```

### `validate-dummy-keys.sh`
**Purpose:** Validates that dummy keys are properly generated and configured for local builds.

---

## 🎵 Audio Hardware Testing

### `detect-audio-hardware.sh`
**Purpose:** Detects and configures audio hardware variants (PDM vs TAS2563 microphones).

### `test-tas2563-mics.sh`
**Purpose:** Tests TAS2563 dual microphone functionality.

### `test-tas2563-sdout.sh`
**Purpose:** Tests TAS2563 Serial Data Output for echo reference capture.

---

## 🛠️ Utilities & Helpers

### `create-archive.sh`
**Purpose:** Creates distribution archives of built images and programming tools.

### `rdc-control.sh`
**Purpose:** i.MX8MM Resource Domain Controller (RDC) management script for runtime peripheral domain assignments.

**Features:**
- Checks RDC driver status and availability
- Shows current peripheral domain assignments
- Provides runtime control over resource domains
- Useful for debugging multi-core resource conflicts

### `toggle-eink-cs.sh`
**Purpose:** Simple script to toggle E-Ink chip select routing between CS0 and CS1 for testing display connectivity.

**Features:**
- Toggles L#R_SEL_DIS (GPIO2_IO16) every 250ms
- Remote execution on target boards via SSH
- Useful for E-Ink display routing verification

### `eink-dual-cs-control.sh`
**Purpose:** Advanced E-Ink dual chip select control for left/right display halves.

**Features:**
- Controls CS0 (GPIO2_IO17) and CS1 (GPIO1_IO11) independently
- Supports sequential, alternating, and simultaneous control modes
- Color-coded logging and comprehensive error handling
- Essential for E-Ink display testing and debugging

---

## 🔍 Hardware Testing & Diagnostics

### `check_ele_status.sh`
**Purpose:** EdgeLock Enclave (ELE) status verification script for i.MX93 boards.

**Features:**
- Checks ELE kernel driver status and device availability
- Verifies secure boot configuration
- Tests ELE-based OCOTP/NVMEM functionality
- Validates ELE hardware random number generator
- Examines ELE crypto driver status

**Usage:**
```bash
# Run directly on target board
./scripts/check_ele_status.sh
```

### `detect-audio-hardware.sh`
**Purpose:** Detects and configures audio hardware variants (PDM vs TAS2563 microphones).

**Features:**
- Automatic detection of audio hardware configuration
- Sets environment variables for ALSA configuration selection
- Persistent configuration storage for consistent behavior
- Runtime hardware switching support

---

## ⏱️ Boot Performance & Timing

### `boot-timing-suite.sh`
**Purpose:** Complete boot analysis workflow combining capture and analysis tools.

**Features:**
- Unified interface for boot timing capture and analysis
- Serial boot log capture with configurable timeouts
- Automated analysis of captured logs
- Comparison mode for multiple boot logs
- Continuous monitoring for boot time regression testing

**Usage:**
```bash
# Complete workflow - capture and analyze
./scripts/boot-timing-suite.sh capture --name imx93-test
./scripts/boot-timing-suite.sh latest

# Custom serial device
./scripts/boot-timing-suite.sh capture --device /dev/ttyUSB0 --name board-v2

# Compare all captured logs
./scripts/boot-timing-suite.sh compare

# Monitor boot times over multiple reboots
./scripts/boot-timing-suite.sh monitor
```

### `serial-boot-logger.sh`
**Purpose:** Captures boot timing data over serial port before networking is available.

**Features:**
- Configurable serial device, baud rate, and timeout
- Timestamped log file generation
- Real-time boot progress monitoring
- Integration with boot analysis tools

### `analyze-boot-logs.sh`
**Purpose:** Processes serial boot logs to extract detailed timing information.

**Features:**
- Detailed timing breakdown by boot phases
- Service timing analysis and optimization recommendations
- Comparison charts for multiple boot logs
- Automated report generation

---

## 🔧 Build System Extensions

### `build-uboot-ele.sh`
**Purpose:** Specialized U-Boot build script with EdgeLock Enclave (ELE) support for i.MX93.

### `kas-build-profiling.sh`
**Purpose:** Builds images with comprehensive profiling enabled for performance analysis.

### `kas-build-mfgtools.sh`
**Purpose:** Builds manufacturing/flashing tools image for board programming.

---

## 📊 Project Management & Documentation

### Issue Management Scripts

#### `add-additional-labels.sh`
**Purpose:** Adds additional categorization labels to GitHub issues.

#### `add-time-estimates.sh`
**Purpose:** Adds time estimate labels to GitHub issues for project planning and resource allocation.

#### `label-software-firmware-issues.sh`
**Purpose:** Automatically categorizes issues as software or firmware related based on content analysis.

#### `organize-issues-by-board.sh`
**Purpose:** Organizes GitHub issues by target board/hardware platform for better project management.

#### `prioritize-all-issues.sh`
**Purpose:** Applies priority labels (critical/high/medium/low) to all issues based on predefined criteria.

#### `update-hardware-issues.sh`
**Purpose:** Updates hardware-related issues with current status and implementation information.

### Issue Creation Scripts

#### `create-board-projects.sh`
**Purpose:** Creates GitHub project boards for organizing board-specific development tasks.

#### `create-identified-issues.sh`
**Purpose:** Batch creates GitHub issues from identified problems, TODO items, or code review feedback.

#### `create-issues-from-review.sh`
**Purpose:** Creates issues from documentation maintenance reviews and code audits.

---

## 📖 Usage Examples

### Complete Development Workflow
```bash
# 1. Set up development environment
export MACHINE=imx93-jaguar-eink
./scripts/generate-dummy-keys.sh

# 2. Build image with profiling
./scripts/build-with-boot-profiling.sh $MACHINE

# 3. Test hardware functionality
./scripts/test-tas2563-mics.sh full

# 4. Create distribution archive
./scripts/create-archive.sh

# 5. Program board
sudo ./scripts/program.sh
```

### CI/CD Maintenance
```bash
# Clean up old workflow runs
./scripts/cleanup-workflow-runs.sh

# Create issues from identified problems
./scripts/create-identified-issues.sh

# Organize and prioritize issues
./scripts/organize-issues-by-board.sh
./scripts/prioritize-all-issues.sh
```

### Foundries.io Deployment
```bash
# Configure for your factory
./scripts/fio-program-board.sh --configure

# Download and program latest build
./scripts/fio-program-board.sh --program

# Program specific target
./scripts/fio-program-board.sh 1451 --program

# Program imx8mm-jaguar-sentai with custom boot files
./scripts/fio-program-board.sh --factory sentai --machine imx8mm-jaguar-sentai --program --mfgfolder program
```

---

## 🔧 Requirements

**General Requirements:**
- Linux development environment (Ubuntu 20.04+ recommended)
- KAS build tool installed
- Git and standard development tools

**For Foundries.io Scripts:**
- `fioctl` installed and authenticated
- Access to Foundries.io factory
- USB access for board programming (sudo privileges)

**For GitHub Management Scripts:**
- GitHub CLI (`gh`) installed and authenticated
- `GITHUB_TOKEN` environment variable or `~/.github_token` file

**For Audio Testing:**
- ALSA utilities (`alsa-utils` package)
- Target hardware connected and accessible

---

## 📝 Notes

- All scripts include comprehensive error handling and logging
- Scripts follow shellcheck linting standards for code quality
- Most scripts support `--help` flag for detailed usage information
- Scripts are designed to be run from the repository root directory