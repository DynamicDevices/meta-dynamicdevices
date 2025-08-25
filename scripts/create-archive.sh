#!/bin/bash

# Script to create a programming archive for any machine
# This archive contains all files needed for programming boards using UUU
#
# Usage:
#   ./create-archive MACHINE_NAME
#
# Example:
#   ./create-archive imx93-jaguar-eink
#   ./create-archive imx8mm-jaguar-handheld
#
# The script will look for build artifacts in:
#   build/tmp/deploy/images/MACHINE_NAME/

set -e

# Show usage if no parameters provided
if [ $# -eq 0 ]; then
    echo "Board Programming Archive Creator"
    echo "================================"
    echo ""
    echo "Usage: $0 MACHINE_NAME"
    echo ""
    echo "Creates a .tgz archive containing all files needed to program boards using UUU."
    echo ""
    echo "Examples:"
    echo "  $0 imx93-jaguar-eink"
    echo "  $0 imx8mm-jaguar-handheld"
    echo "  $0 imx8mm-jaguar-phasora"
    echo ""
    echo "Available machines in build directory:"
    if [ -d "build/tmp/deploy/images" ]; then
        find build/tmp/deploy/images/ -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sed 's/^/  /' || echo "  No machines found"
    else
        echo "  No build directory found (build/tmp/deploy/images/)"
    fi
    echo ""
    echo "The script will create: MACHINE_NAME-GIT_HASH-STATUS.tgz"
    echo "  where STATUS is 'clean' if no uncommitted changes, 'dirty' if there are changes"
    echo ""
    exit 1
fi

# Get machine name from parameter
MACHINE="$1"
BUILD_DIR="build/tmp/deploy/images/${MACHINE}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get git commit hash and status for archive naming
GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_STATUS=$(git diff-index --quiet HEAD -- 2>/dev/null && echo "clean" || echo "dirty")
ARCHIVE_NAME="${MACHINE}-${GIT_HASH}-${GIT_STATUS}"
TEMP_DIR="/tmp/${ARCHIVE_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if build directory exists
if [ ! -d "${BUILD_DIR}" ]; then
    error "Build directory not found: ${BUILD_DIR}"
fi

# Check if mfgtool-files exists
if [ ! -d "${BUILD_DIR}/mfgtool-files" ]; then
    error "mfgtool-files directory not found in ${BUILD_DIR}"
fi

log "Creating archive for ${MACHINE}"
log "Build directory: ${BUILD_DIR}"
log "Archive name: ${ARCHIVE_NAME}"

# Create temporary directory
rm -rf "${TEMP_DIR}"
mkdir -p "${TEMP_DIR}"

# Copy mfgtool-files directory (contains uuu executables and scripts)
log "Copying mfgtool-files directory..."
cp -r "${BUILD_DIR}/mfgtool-files" "${TEMP_DIR}/"

# Copy main image file (wic.gz)
log "Copying main image file..."
if [ -f "${BUILD_DIR}/lmp-factory-image-${MACHINE}.wic.gz" ]; then
    cp "${BUILD_DIR}/lmp-factory-image-${MACHINE}.wic.gz" "${TEMP_DIR}/"
else
    error "Main image file not found: lmp-factory-image-${MACHINE}.wic.gz"
fi

# Copy bootloader files
log "Copying bootloader files..."
BOOTLOADER_FILES=(
    "imx-boot-${MACHINE}"
    "u-boot-${MACHINE}.itb"
)

for file in "${BOOTLOADER_FILES[@]}"; do
    if [ -f "${BUILD_DIR}/${file}" ]; then
        cp "${BUILD_DIR}/${file}" "${TEMP_DIR}/"
        log "  ✓ ${file}"
    else
        error "Required bootloader file not found: ${file}"
    fi
done

# Copy device tree files (optional, but useful for reference)
log "Copying device tree file..."
if [ -f "${BUILD_DIR}/${MACHINE}.dtb" ]; then
    cp "${BUILD_DIR}/${MACHINE}.dtb" "${TEMP_DIR}/"
    log "  ✓ ${MACHINE}.dtb"
else
    warn "Device tree file not found: ${MACHINE}.dtb (optional)"
fi

# Copy image manifest for reference
log "Copying image manifest..."
if [ -f "${BUILD_DIR}/lmp-factory-image-${MACHINE}.manifest" ]; then
    cp "${BUILD_DIR}/lmp-factory-image-${MACHINE}.manifest" "${TEMP_DIR}/"
    log "  ✓ Image manifest"
else
    warn "Image manifest not found (optional)"
fi

# Create a README file with programming instructions
log "Creating README file..."
cat > "${TEMP_DIR}/README.md" << EOF
# ${MACHINE} Board Programming Guide

This archive contains all necessary files to program ${MACHINE} boards using NXP's UUU (Universal Update Utility).

## Contents

- **mfgtool-files/**: Directory containing UUU executables and programming scripts
  - \`uuu\`: Linux executable
  - \`uuu.exe\`: Windows executable  
  - \`uuu_mac_arm\`: macOS ARM executable
  - \`uuu_mac_x86\`: macOS x86 executable
  - \`full_image.uuu\`: Complete image programming script
  - \`bootloader.uuu\`: Bootloader-only programming script
  - \`imx-boot-mfgtool\`: Manufacturing boot image
  - \`u-boot-mfgtool.itb\`: Manufacturing U-Boot image

- **lmp-factory-image-${MACHINE}.wic.gz**: Main system image
- **imx-boot-${MACHINE}**: Production bootloader
- **u-boot-${MACHINE}.itb**: Production U-Boot image
- **${MACHINE}.dtb**: Device tree blob (if available)

## Programming Instructions

### Prerequisites
1. Connect the board to your host via USB (USB-C connector in download mode)
2. Put the board in download mode (refer to board documentation)
3. Ensure you have appropriate drivers installed

### Linux/macOS Programming
\`\`\`bash
# Make the UUU executable
chmod +x mfgtool-files/uuu

# Program complete image (bootloader + filesystem)
./mfgtool-files/uuu mfgtool-files/full_image.uuu

# OR program bootloader only
./mfgtool-files/uuu mfgtool-files/bootloader.uuu
\`\`\`

### Windows Programming
\`\`\`cmd
# Program complete image (bootloader + filesystem)
mfgtool-files\\uuu.exe mfgtool-files\\full_image.uuu

# OR program bootloader only  
mfgtool-files\\uuu.exe mfgtool-files\\bootloader.uuu
\`\`\`

### macOS Programming
\`\`\`bash
# For ARM-based Macs
chmod +x mfgtool-files/uuu_mac_arm
./mfgtool-files/uuu_mac_arm mfgtool-files/full_image.uuu

# For Intel-based Macs  
chmod +x mfgtool-files/uuu_mac_x86
./mfgtool-files/uuu_mac_x86 mfgtool-files/full_image.uuu
\`\`\`

## Troubleshooting

1. **Device not detected**: Ensure the board is in download mode and USB drivers are installed
2. **Permission denied**: On Linux/macOS, you may need to run with sudo or add udev rules
3. **Programming fails**: Check USB connection and try a different USB port
4. **Slow programming**: Use a USB 3.0 port if available

## Build Information

- Machine: ${MACHINE}
- Build date: $(date)
- Archive created: $(date)

Generated by: create_archive.sh
EOF

# Create version info file
log "Creating version info..."
cat > "${TEMP_DIR}/version_info.txt" << EOF
Build Information for ${MACHINE}
================================

Build Date: $(date)
Machine: ${MACHINE}
Archive: ${ARCHIVE_NAME}
Git Commit: ${GIT_HASH}
Git Status: ${GIT_STATUS}
Git Branch: $(git branch --show-current 2>/dev/null || echo "unknown")

File Checksums (SHA256):
$(cd "${TEMP_DIR}" && find . -type f -name "*.wic.gz" -o -name "imx-boot-*" -o -name "u-boot-*.itb" -o -name "*.dtb" | sort | xargs sha256sum 2>/dev/null || echo "sha256sum not available")

UUU Scripts:
$(ls -la "${TEMP_DIR}/mfgtool-files/"*.uuu 2>/dev/null || echo "No UUU scripts found")
EOF

# Show summary of what will be archived
log "Archive contents summary:"
du -sh "${TEMP_DIR}"/* | sort -hr

# Create the archive
ARCHIVE_PATH="${SCRIPT_DIR}/${ARCHIVE_NAME}.tgz"
log "Creating archive: ${ARCHIVE_PATH}"

cd "$(dirname "${TEMP_DIR}")"
tar -czf "${ARCHIVE_PATH}" "$(basename "${TEMP_DIR}")"

# Cleanup temporary directory
rm -rf "${TEMP_DIR}"

# Final summary
ARCHIVE_SIZE=$(du -sh "${ARCHIVE_PATH}" | cut -f1)
log "✅ Archive created successfully!"
log "   File: ${ARCHIVE_PATH}"
log "   Size: ${ARCHIVE_SIZE}"
log ""
log "📋 To use this archive:"
log "   1. Extract: tar -xzf ${ARCHIVE_NAME}.tgz"
log "   2. Follow instructions in ${ARCHIVE_NAME}/README.md"
log "   3. Use appropriate UUU executable for your platform"
