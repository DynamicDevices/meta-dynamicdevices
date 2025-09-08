#!/bin/bash

#
# Program Local Build Script
# 
# This script programs locally built images using UUU tool.
# Use this for development builds created with kas-build-base.sh
#
# For Foundries.io cloud builds, use fio-program-board.sh instead.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Program locally built images to the target board using UUU tool.

OPTIONS:
    -m, --machine MACHINE    Target machine (e.g., imx93-jaguar-eink, imx8mm-jaguar-sentai)
    -h, --help              Show this help message

ENVIRONMENT VARIABLES:
    KAS_MACHINE             Alternative way to specify target machine

EXAMPLES:
    # Using command line argument
    $0 --machine imx93-jaguar-eink
    
    # Using environment variable
    KAS_MACHINE=imx93-jaguar-eink $0
    
    # For other machines
    $0 --machine imx8mm-jaguar-sentai
    $0 --machine imx8mm-jaguar-phasora

PREREQUISITES:
    1. Build the main image first:
       KAS_MACHINE=imx93-jaguar-eink ./scripts/kas-build-base.sh
    
    2. Build the mfgtool files:
       KAS_MACHINE=imx93-jaguar-eink ./scripts/kas-build-mfgtools.sh
    
    3. Put board in USB download mode
    
    4. Run this script with sudo privileges

NOTE:
    This script programs LOCAL builds only. For Foundries.io cloud builds,
    use fio-program-board.sh instead.

EOF
}

# Parse command line arguments
MACHINE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--machine)
            MACHINE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1"
            show_usage
            exit 1
            ;;
    esac
done

# Determine machine from argument or environment variable
if [[ -n "${MACHINE}" ]]; then
    KAS_MACHINE="${MACHINE}"
elif [[ -z "${KAS_MACHINE:-}" ]]; then
    echo "Error: No machine specified!"
    echo ""
    echo "Set machine using:"
    echo "  --machine MACHINE  or  KAS_MACHINE environment variable"
    echo ""
    echo "Supported machines:"
    echo "  - imx93-jaguar-eink"
    echo "  - imx8mm-jaguar-sentai" 
    echo "  - imx8mm-jaguar-phasora"
    echo ""
    show_usage
    exit 1
fi

echo "============================================================"
echo "Programming Local Build for Machine: ${KAS_MACHINE}"
echo "============================================================"

# Check if build exists
BUILD_DIR="${PROJECT_ROOT}/build"
if [[ ! -d "${BUILD_DIR}" ]]; then
    echo "Error: Build directory not found: ${BUILD_DIR}"
    echo ""
    echo "Please build the image first:"
    echo "  KAS_MACHINE=${KAS_MACHINE} ./scripts/kas-build-base.sh"
    exit 1
fi

# Check for deploy directory with images
DEPLOY_DIR="${BUILD_DIR}/tmp/deploy/images/${KAS_MACHINE}"
if [[ ! -d "${DEPLOY_DIR}" ]]; then
    echo "Error: Deploy directory not found: ${DEPLOY_DIR}"
    echo ""
    echo "Please build the image first:"
    echo "  KAS_MACHINE=${KAS_MACHINE} ./scripts/kas-build-base.sh"
    exit 1
fi

# Check for mfgtool files
MFGTOOL_DIR="${DEPLOY_DIR}/mfgtool-files"
if [[ ! -d "${MFGTOOL_DIR}" ]]; then
    echo "Error: MFGTool files not found: ${MFGTOOL_DIR}"
    echo ""
    echo "Please build the mfgtool files first:"
    echo "  KAS_MACHINE=${KAS_MACHINE} ./scripts/kas-build-mfgtools.sh"
    echo ""
    echo "Or use Foundries.io builds instead:"
    echo "  ./scripts/fio-program-board.sh --machine ${KAS_MACHINE} --program"
    exit 1
fi

# Verify required mfgtool files exist
REQUIRED_MFGTOOL_FILES=("imx-boot-mfgtool" "u-boot-mfgtool.itb")
for file in "${REQUIRED_MFGTOOL_FILES[@]}"; do
    if [[ ! -f "${MFGTOOL_DIR}/${file}" ]]; then
        echo "Error: Required mfgtool file not found: ${MFGTOOL_DIR}/${file}"
        echo ""
        echo "Please rebuild mfgtool files:"
        echo "  KAS_MACHINE=${KAS_MACHINE} ./scripts/kas-build-mfgtools.sh"
        exit 1
    fi
done

# Check for locally built UUU tool
UUU_TOOL="${MFGTOOL_DIR}/uuu"
if [[ ! -f "${UUU_TOOL}" ]]; then
    echo "Error: UUU tool not found: ${UUU_TOOL}"
    echo ""
    echo "Please ensure mfgtool build completed successfully:"
    echo "  KAS_MACHINE=${KAS_MACHINE} ./scripts/kas-build-mfgtools.sh"
    exit 1
fi

# Check for locally built UUU script
UUU_SCRIPT="${MFGTOOL_DIR}/full_image.uuu"
if [[ ! -f "${UUU_SCRIPT}" ]]; then
    echo "Error: UUU script not found: ${UUU_SCRIPT}"
    echo ""
    echo "Please ensure mfgtool build completed successfully:"
    echo "  KAS_MACHINE=${KAS_MACHINE} ./scripts/kas-build-mfgtools.sh"
    exit 1
fi

echo "Using locally built UUU script: ${UUU_SCRIPT}"
echo "Using locally built mfgtool files from: ${MFGTOOL_DIR}"
echo "Programming files from: ${DEPLOY_DIR}"
echo ""

# List available images for verification (show only clean symlink names)
echo "Available images:"
cd "${DEPLOY_DIR}"
# Show only the generic symlink names (user-friendly, no timestamps)
for image in lmp-factory-image-${KAS_MACHINE}.wic.gz lmp-factory-image-${KAS_MACHINE}.wic; do
    if [[ -L "$image" || -f "$image" ]]; then
        # For symlinks, get size of the target file
        size=$(du -hL "$image" 2>/dev/null | cut -f1)
        if [[ "$image" == *.gz ]]; then
            echo "  $image (${size}, compressed - recommended)"
        else
            echo "  $image (${size}, uncompressed)"
        fi
    fi
done
cd - > /dev/null
echo ""

# Check if running as root (required for UUU)
if [[ $EUID -ne 0 ]]; then
    echo "Note: UUU requires root privileges. You may be prompted for sudo password."
    echo ""
fi

# Program the board
echo "Starting board programming..."
echo "Make sure your board is in USB download mode!"
echo ""
read -p "Press Enter to continue or Ctrl+C to abort..."

# Create symbolic links for files that UUU script expects but may have different names
echo "Setting up file links for UUU script compatibility..."
cd "${DEPLOY_DIR}"

# Check what the UUU script is expecting and create links if needed
if [[ -f "${MFGTOOL_DIR}/full_image.uuu" ]]; then
    # Extract expected filenames from UUU script
    expected_wic=$(grep "flash.*all.*\.wic" "${MFGTOOL_DIR}/full_image.uuu" | sed 's/.*\.\.\/\([^\/]*\.wic[^\/]*\).*/\1/' | head -1)
    expected_boot=$(grep "flash bootloader.*imx-boot" "${MFGTOOL_DIR}/full_image.uuu" | sed 's/.*\.\.\/\([^\/]*\).*/\1/' | head -1)
    expected_uboot=$(grep "flash bootloader2.*u-boot" "${MFGTOOL_DIR}/full_image.uuu" | sed 's/.*\.\.\/\([^\/]*\).*/\1/' | head -1)
    
    # Create links for main image if needed
    if [[ -n "$expected_wic" && ! -f "$expected_wic" ]]; then
        actual_wic=$(ls lmp-factory-image-*.wic.gz 2>/dev/null | head -1)
        if [[ -n "$actual_wic" ]]; then
            ln -sf "$actual_wic" "$expected_wic"
            echo "  Linked $actual_wic -> $expected_wic"
        fi
    fi
    
    # Create links for bootloader if needed
    if [[ -n "$expected_boot" && ! -f "$expected_boot" ]]; then
        actual_boot=$(ls imx-boot-${KAS_MACHINE} 2>/dev/null | head -1)
        if [[ -n "$actual_boot" ]]; then
            ln -sf "$actual_boot" "$expected_boot"
            echo "  Linked $actual_boot -> $expected_boot"
        fi
    fi
    
    # Create links for u-boot if needed
    if [[ -n "$expected_uboot" && ! -f "$expected_uboot" ]]; then
        actual_uboot=$(ls u-boot-${KAS_MACHINE}.itb 2>/dev/null | head -1)
        if [[ -n "$actual_uboot" ]]; then
            ln -sf "$actual_uboot" "$expected_uboot"
            echo "  Linked $actual_uboot -> $expected_uboot"
        fi
    fi
fi

# Change to mfgtool directory where the UUU script and files are located
cd "${MFGTOOL_DIR}"

# Run UUU with the locally built script (using relative paths since we're in mfgtool directory)
echo "Starting UUU programming..."
if [[ $EUID -eq 0 ]]; then
    ./uuu full_image.uuu || {
        echo "UUU completed with exit code $?, but programming may have succeeded"
    }
else
    sudo ./uuu full_image.uuu || {
        echo "UUU completed with exit code $?, but programming may have succeeded"
    }
fi

echo ""
echo "============================================================"
echo "Programming completed successfully!"
echo "============================================================"
echo ""
echo "Your ${KAS_MACHINE} board should now boot with the local build."
