#!/bin/bash
# Build script with boot profiling enabled for Dynamic Devices boards
# Usage: ./build-with-boot-profiling.sh [MACHINE]
# Target: 1-2 second boot time optimization

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default machine if not specified
MACHINE="${1:-imx93-jaguar-eink}"

echo "=== Dynamic Devices Boot Profiling Build ==="
echo "Machine: $MACHINE"
echo "Target: 1-2 second boot time"
echo ""

# Validate machine
case "$MACHINE" in
    imx93-jaguar-eink|imx8mm-jaguar-sentai)
        echo "Building for supported machine: $MACHINE"
        ;;
    *)
        echo "Error: Unsupported machine '$MACHINE'"
        echo "Supported machines: imx93-jaguar-eink, imx8mm-jaguar-sentai"
        exit 1
        ;;
esac

# Set environment variables for boot profiling
export ENABLE_BOOT_PROFILING=1
export KAS_MACHINE="$MACHINE"

echo "=== Boot Profiling Configuration ==="
echo "ENABLE_BOOT_PROFILING=$ENABLE_BOOT_PROFILING"
echo "KAS_MACHINE=$KAS_MACHINE"
echo ""

echo "This build will include:"
echo "  - U-Boot boot timing (bootstage, bootdelay=0)"
echo "  - Kernel initcall debugging and timing"
echo "  - Systemd service analysis tools"
echo "  - Boot analysis scripts and services"
echo "  - Performance profiling tools"
echo ""

# Change to project root
cd "$PROJECT_ROOT"

# Build with KAS
echo "=== Starting KAS Build ==="
echo "Command: kas build kas/lmp-dynamicdevices.yml"
echo ""

if ! kas build kas/lmp-dynamicdevices.yml; then
    echo "Error: Build failed"
    exit 1
fi

echo ""
echo "=== Build Complete ==="
echo ""
echo "Boot profiling is now enabled in the image."
echo ""
echo "After flashing and booting the board:"
echo "  1. Boot analysis runs automatically via systemd service"
echo "  2. Manual analysis: run 'boot-analysis.sh'"
echo "  3. Live monitoring: run 'profile-boot.sh --live'"
echo "  4. Systemd analysis: run 'systemd-analyze blame'"
echo "  5. View boot logs: check /var/log/boot-profiling/"
echo ""
echo "Boot optimization targets:"
echo "  - U-Boot: < 0.5s (bootdelay=0, optimized config)"
echo "  - Kernel: < 1.0s (minimal drivers, initcall timing)"
echo "  - Systemd: < 0.5s (essential services only)"
echo "  - Total target: 1-2 seconds"
echo ""
echo "Image location: build/tmp/deploy/images/$MACHINE/"
echo "Flash with: ./scripts/program.sh"
