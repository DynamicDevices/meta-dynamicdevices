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
    --mfgfolder DIR         Custom folder containing imx-boot-mfgtool and u-boot-mfgtool.itb files
                            (Files are used directly from this folder, not copied)
                            (Relative paths are relative to current working directory)
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
    
    # Use custom boot firmware files
    $0 --machine imx8mm-jaguar-sentai --mfgfolder /path/to/custom/boot/files
    $0 --machine imx8mm-jaguar-sentai --mfgfolder ./custom-boot-files

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
MFGFOLDER=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--machine)
            MACHINE="$2"
            shift 2
            ;;
        --mfgfolder)
            MFGFOLDER="$2"
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

# Resolve mfgfolder path if provided (relative to current working directory)
RESOLVED_MFGFOLDER=""
if [[ -n "$MFGFOLDER" ]]; then
    if [[ "$MFGFOLDER" = /* ]]; then
        # Already absolute path
        RESOLVED_MFGFOLDER="$MFGFOLDER"
    else
        # Relative path - make it relative to current working directory
        RESOLVED_MFGFOLDER="$(pwd)/$MFGFOLDER"
    fi
    echo "Custom boot firmware folder: $RESOLVED_MFGFOLDER"
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

# Validate custom mfgfolder if specified
if [[ -n "$RESOLVED_MFGFOLDER" ]]; then
    echo ""
    echo "Validating custom boot firmware files..."
    
    # Validate custom folder exists and has required files
    if [[ ! -d "$RESOLVED_MFGFOLDER" ]]; then
        echo "Error: Custom mfgfolder does not exist: $RESOLVED_MFGFOLDER"
        exit 1
    fi
    
    MISSING_FILES=()
    if [[ ! -f "$RESOLVED_MFGFOLDER/imx-boot-mfgtool" ]]; then
        MISSING_FILES+=("imx-boot-mfgtool")
    fi
    if [[ ! -f "$RESOLVED_MFGFOLDER/u-boot-mfgtool.itb" ]]; then
        MISSING_FILES+=("u-boot-mfgtool.itb")
    fi
    
    if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
        echo "Error: Missing required files in custom mfgfolder: $RESOLVED_MFGFOLDER"
        for file in "${MISSING_FILES[@]}"; do
            echo "  - $file"
        done
        exit 1
    fi
    
    echo "Custom boot firmware files validated:"
    echo "  - imx-boot-mfgtool: $(du -h "$RESOLVED_MFGFOLDER/imx-boot-mfgtool" | cut -f1)"
    echo "  - u-boot-mfgtool.itb: $(du -h "$RESOLVED_MFGFOLDER/u-boot-mfgtool.itb" | cut -f1)"
    echo "  Will use files from: $RESOLVED_MFGFOLDER"
fi

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

# Run UUU with the locally built script
echo "Starting UUU programming..."

if [[ -n "$RESOLVED_MFGFOLDER" ]]; then
    # Use custom boot firmware files - create temporary symbolic links in mfgtool directory
    echo "Creating temporary links to custom boot firmware files..."
    cd "${MFGTOOL_DIR}"
    
    # Create temporary links to custom files (will override the originals during execution)
    ln -sf "$RESOLVED_MFGFOLDER/imx-boot-mfgtool" "./imx-boot-mfgtool-custom"
    ln -sf "$RESOLVED_MFGFOLDER/u-boot-mfgtool.itb" "./u-boot-mfgtool-custom.itb"
    
    # Create a temporary UUU script that uses the custom files
    sed 's|imx-boot-mfgtool|imx-boot-mfgtool-custom|g; s|u-boot-mfgtool\.itb|u-boot-mfgtool-custom.itb|g' full_image.uuu > full_image_custom.uuu
    
    if [[ $EUID -eq 0 ]]; then
        ./uuu full_image_custom.uuu || {
            echo "UUU completed with exit code $?, but programming may have succeeded"
        }
    else
        sudo ./uuu full_image_custom.uuu || {
            echo "UUU completed with exit code $?, but programming may have succeeded"
        }
    fi
    
    # Cleanup temporary files
    rm -f "./imx-boot-mfgtool-custom" "./u-boot-mfgtool-custom.itb" "./full_image_custom.uuu"
else
    # Use original files - change to mfgtool directory where the UUU script and files are located
    cd "${MFGTOOL_DIR}"
    
    # Run UUU with the locally built script (using relative paths since we're in mfgtool directory)
    if [[ $EUID -eq 0 ]]; then
        ./uuu full_image.uuu || {
            echo "UUU completed with exit code $?, but programming may have succeeded"
        }
    else
        sudo ./uuu full_image.uuu || {
            echo "UUU completed with exit code $?, but programming may have succeeded"
        }
    fi
fi

echo ""
echo "============================================================"
echo "Programming completed successfully!"
echo "============================================================"
echo ""
echo "Your ${KAS_MACHINE} board should now boot with the local build."
