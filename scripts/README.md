# Scripts Directory

This directory contains utility scripts for building, testing, managing, and automating the meta-dynamicdevices BSP layer development workflow.

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

### `program.sh`
**Purpose:** Programs a board using UUU (Universal Update Utility) with locally built images.

**Usage:**
```bash
# Program board (with board in download mode)
sudo ./scripts/program.sh
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