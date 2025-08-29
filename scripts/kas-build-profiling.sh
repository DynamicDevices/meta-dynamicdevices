#!/bin/bash
# KAS build script with boot profiling enabled for Dynamic Devices boards
# Usage: ./kas-build-profiling.sh [MACHINE] [TARGET]
# Target: 1-2 second boot time optimization

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
DEFAULT_MACHINE="imx93-jaguar-eink"
DEFAULT_TARGET="lmp-factory-image"

MACHINE="${1:-$DEFAULT_MACHINE}"
TARGET="${2:-$DEFAULT_TARGET}"

echo "=== Dynamic Devices KAS Build with Boot Profiling ==="
echo "Machine: $MACHINE"
echo "Target: $TARGET"
echo "Boot profiling: ENABLED"
echo ""

# Validate machine
case "$MACHINE" in
    imx93-jaguar-eink|imx8mm-jaguar-sentai|imx8mm-jaguar-inst|imx8mm-jaguar-handheld|imx8mm-jaguar-phasora)
        echo "✓ Building for supported machine: $MACHINE"
        ;;
    *)
        echo "❌ Error: Unsupported machine '$MACHINE'"
        echo "Supported machines:"
        echo "  - imx93-jaguar-eink (default)"
        echo "  - imx8mm-jaguar-sentai"
        echo "  - imx8mm-jaguar-inst"
        echo "  - imx8mm-jaguar-handheld"
        echo "  - imx8mm-jaguar-phasora"
        exit 1
        ;;
esac

# Set environment variables for boot profiling
export ENABLE_BOOT_PROFILING=1
export KAS_MACHINE="$MACHINE"

echo "=== Environment Configuration ==="
echo "ENABLE_BOOT_PROFILING=$ENABLE_BOOT_PROFILING"
echo "KAS_MACHINE=$KAS_MACHINE"
echo "TARGET=$TARGET"
echo ""

echo "=== Boot Profiling Features ==="
echo "This build includes:"
echo "  ✓ U-Boot timing measurement (bootstage, bootdelay=0)"
echo "  ✓ Kernel initcall debugging and driver timing"
echo "  ✓ Systemd service analysis tools (systemd-analyze)"
echo "  ✓ Boot analysis scripts (/usr/bin/boot-analysis.sh)"
echo "  ✓ Interactive profiling tools (/usr/bin/profile-boot.sh)"
echo "  ✓ Performance monitoring tools (perf, strace, htop)"
echo "  ✓ Automatic boot analysis service"
echo ""

# Change to project root
cd "$PROJECT_ROOT"

# Check if kas-container is available
if ! command -v kas-container >/dev/null 2>&1; then
    echo "❌ Error: kas-container command not found"
    echo "Please install kas-container for containerized builds"
    echo ""
    echo "Install with: pip3 install kas[container]"
    exit 1
fi

# Set up Yocto cache directories (identical to kas-build-base.sh)
if [ ! -d ~/yocto ]
then
  mkdir -p ~/yocto
  mkdir -p ~/yocto/downloads
  mkdir -p ~/yocto/persistent
  mkdir -p ~/yocto/sstate
  chmod 755 ~/yocto
  chmod 755 ~/yocto/downloads
  chmod 755 ~/yocto/persistent
  chmod 755 ~/yocto/sstate
fi

# Start the build
echo "=== Starting KAS Container Build ==="
echo "Command: kas-container --runtime-args \"-v \${HOME}/yocto:/var/cache\" build kas/lmp-dynamicdevices.yml"
echo "Working directory: $(pwd)"
echo ""
echo "=== Build Optimization ==="
echo "✓ Using containerized build environment (kas-container)"
echo "✓ Persistent cache: ~/yocto/sstate (shared state cache)"
echo "✓ Persistent downloads: ~/yocto/downloads (source downloads)"
echo "✓ This significantly reduces rebuild times"
echo ""

# Run the build using kas-container
if kas-container --runtime-args "-v ${HOME}/yocto:/var/cache" build "kas/lmp-dynamicdevices.yml"; then
    echo ""
    echo "=== ✅ Build Successful ==="
    echo ""
    echo "Image location: build/tmp/deploy/images/$MACHINE/"
    echo ""
    echo "=== Next Steps ==="
    echo "1. Flash the image:"
    echo "   ./scripts/program.sh"
    echo ""
    echo "2. After booting, analyze boot performance:"
    echo "   boot-analysis.sh                    # Comprehensive analysis"
    echo "   systemd-analyze blame               # Service timing"
    echo "   profile-boot.sh --live              # Live monitoring"
    echo ""
    echo "3. View boot analysis reports:"
    echo "   ls /var/log/boot-profiling/         # Analysis reports"
    echo "   systemd-analyze critical-chain      # Critical path"
    echo ""
    echo "=== Boot Time Targets ==="
    echo "  U-Boot:  < 0.5s (bootloader + hardware init)"
    echo "  Kernel:  < 1.0s (kernel init + drivers)"
    echo "  Systemd: < 0.5s (services + userspace)"
    echo "  Total:   < 2.0s (power-on to login)"
    echo ""
else
    echo ""
    echo "=== ❌ Build Failed ==="
    echo ""
    echo "Check the build log for errors."
    echo "Common issues:"
    echo "  - Missing dependencies (check kas environment)"
    echo "  - Network connectivity (for layer downloads)"
    echo "  - Disk space (builds require significant space)"
    echo ""
    exit 1
fi
