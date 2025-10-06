#!/bin/bash
#
# KAS Boot-Level Development Script
#
# This script handles development that requires U-Boot access and serial console interaction.
# Use this for: bootloader changes, device tree modifications, boot process debugging.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# Default values
ACTION=""
MACHINE="${KAS_MACHINE:-imx93-jaguar-eink}"
SERIAL_DEVICE="${SERIAL_DEVICE:-/dev/ttyUSB1}"
BAUD_RATE="${BAUD_RATE:-115200}"
BOOT_TIMEOUT=120
COMPONENT=""
INTERACTIVE=false

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 ACTION [OPTIONS]

Boot-level development workflow using kas-container and serial console access.
Use this for bootloader, device tree, and early boot development.

ACTIONS:
    build-uboot             Build U-Boot only
    build-dtbs              Build device tree blobs only
    build-boot              Build complete boot components (U-Boot + DTBs)
    program-boot            Program boot components and test via serial
    test-boot               Test current boot process via serial console
    interactive             Start interactive serial console
    monitor                 Monitor serial output (read-only)
    uboot-shell             Access U-Boot shell via serial console

OPTIONS:
    -m, --machine MACHINE    Target machine (default: \$KAS_MACHINE or imx93-jaguar-eink)
    -d, --device DEVICE      Serial device (default: \$SERIAL_DEVICE or /dev/ttyUSB1)
    -b, --baud RATE          Baud rate (default: \$BAUD_RATE or 115200)
    -t, --timeout SECONDS    Boot timeout (default: 120)
    -c, --component COMP     Specific component (uboot, dtb, spl)
    -i, --interactive        Interactive mode for testing
    -h, --help              Show this help message

ENVIRONMENT VARIABLES:
    KAS_MACHINE             Target machine
    SERIAL_DEVICE           Serial device path
    BAUD_RATE               Serial baud rate

EXAMPLES:
    # Build and program U-Boot, then test boot
    $0 build-uboot --machine imx93-jaguar-eink
    $0 program-boot --interactive
    
    # Build device trees and test
    $0 build-dtbs
    $0 test-boot --timeout 180
    
    # Access U-Boot shell for debugging
    $0 uboot-shell --device /dev/ttyUSB0
    
    # Monitor boot process
    $0 monitor --timeout 60
    
    # Interactive serial console
    $0 interactive

PREREQUISITES:
    1. KAS development environment set up
    2. Serial console connected to board
    3. Board in boot mode (not programming mode)
    4. Python3 with pyserial installed

WORKFLOW:
    1. Make bootloader/device tree changes
    2. Build components: $0 build-boot
    3. Program board: ./scripts/program-local-build.sh --machine \$MACHINE
    4. Test boot: $0 test-boot
    5. Debug if needed: $0 uboot-shell or $0 interactive

EOF
}

# Ensure yocto cache directories exist
setup_cache_dirs() {
    if [ ! -d ~/yocto ]; then
        mkdir -p ~/yocto
        mkdir -p ~/yocto/downloads
        mkdir -p ~/yocto/persistent
        mkdir -p ~/yocto/sstate
        chmod 755 ~/yocto
        chmod 755 ~/yocto/downloads
        chmod 755 ~/yocto/persistent
        chmod 755 ~/yocto/sstate
    fi
}

# Check serial device availability
check_serial_device() {
    if [ ! -e "$SERIAL_DEVICE" ]; then
        echo "❌ Error: Serial device $SERIAL_DEVICE not found"
        echo "💡 Available devices:"
        ls -la /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || echo "  No USB serial devices found"
        echo "💡 Check USB connection and try: sudo usermod -a -G dialout \$USER"
        exit 1
    fi
    
    if [ ! -r "$SERIAL_DEVICE" ] || [ ! -w "$SERIAL_DEVICE" ]; then
        echo "❌ Error: No permission to access $SERIAL_DEVICE"
        echo "💡 Try: sudo usermod -a -G dialout \$USER (then logout/login)"
        echo "💡 Or run with: sudo $0 $ACTION"
        exit 1
    fi
}

# Build U-Boot using kas
build_uboot() {
    echo "🔨 Building U-Boot for $MACHINE..."
    setup_cache_dirs
    
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices.yml \
        -c "bitbake virtual/bootloader -c deploy"
    
    echo "✅ U-Boot build complete for $MACHINE"
    echo "📁 Artifacts in: build/tmp/deploy/images/$MACHINE/"
    ls -la "build/tmp/deploy/images/$MACHINE/" | grep -E "(imx-boot|u-boot)" || true
}

# Build device tree blobs
build_dtbs() {
    echo "🔨 Building device tree blobs for $MACHINE..."
    setup_cache_dirs
    
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices.yml \
        -c "bitbake virtual/kernel -c compile && bitbake virtual/kernel -c dtbs"
    
    echo "✅ Device tree build complete"
    echo "📁 DTB files in: build/tmp/deploy/images/$MACHINE/"
    ls -la "build/tmp/deploy/images/$MACHINE/"*.dtb 2>/dev/null || true
}

# Build complete boot components
build_boot() {
    echo "🔨 Building complete boot components for $MACHINE..."
    setup_cache_dirs
    
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices.yml \
        -c "bitbake virtual/bootloader virtual/kernel -c deploy"
    
    echo "✅ Boot components build complete"
    echo "📁 Boot artifacts:"
    ls -la "build/tmp/deploy/images/$MACHINE/" | grep -E "(imx-boot|u-boot|Image|\.dtb)" || true
}

# Program boot components and test
program_boot() {
    echo "🔄 Programming boot components for $MACHINE..."
    
    # First build if needed
    if [ ! -d "build/tmp/deploy/images/$MACHINE" ]; then
        echo "📦 No build artifacts found, building first..."
        build_boot
    fi
    
    # Program using existing script
    echo "📤 Programming board..."
    ./scripts/program-local-build.sh --machine "$MACHINE"
    
    if [ "$INTERACTIVE" = true ]; then
        echo "🔍 Starting interactive boot test..."
        echo "💡 Change boot pins from programming to boot mode, then press Enter"
        read -p "Ready to test boot? "
        test_boot
    else
        echo "✅ Programming complete"
        echo "💡 Change boot pins to boot mode and run: $0 test-boot"
    fi
}

# Test boot process via serial console
test_boot() {
    echo "🧪 Testing boot process via serial console..."
    check_serial_device
    
    if [ ! -f "$SCRIPT_DIR/serial_console/test_boot_process.py" ]; then
        echo "❌ Error: Boot test script not found"
        echo "Expected: $SCRIPT_DIR/serial_console/test_boot_process.py"
        exit 1
    fi
    
    echo "🔌 Using serial device: $SERIAL_DEVICE at $BAUD_RATE baud"
    echo "⏱️  Boot timeout: $BOOT_TIMEOUT seconds"
    echo ""
    
    cd "$SCRIPT_DIR/serial_console"
    python3 test_boot_process.py \
        --device "$SERIAL_DEVICE" \
        --baud "$BAUD_RATE" \
        --timeout "$BOOT_TIMEOUT"
    
    echo ""
    echo "✅ Boot test complete"
    echo "📄 Check generated log file for detailed results"
}

# Access U-Boot shell
uboot_shell() {
    echo "🐚 Accessing U-Boot shell via serial console..."
    check_serial_device
    
    echo "💡 Instructions:"
    echo "  1. Reset/power cycle the board"
    echo "  2. Press any key when you see 'Hit any key to stop autoboot'"
    echo "  3. You'll get U-Boot prompt: => "
    echo "  4. Use Ctrl+] to exit"
    echo ""
    echo "🔌 Using serial device: $SERIAL_DEVICE at $BAUD_RATE baud"
    echo "Press Enter to start..."
    read
    
    if [ -f "$SCRIPT_DIR/serial_console/serial_console.py" ]; then
        cd "$SCRIPT_DIR/serial_console"
        python3 serial_console.py \
            --device "$SERIAL_DEVICE" \
            --baud "$BAUD_RATE" \
            --timestamps
    else
        echo "❌ Error: Serial console script not found"
        echo "Falling back to screen..."
        screen "$SERIAL_DEVICE" "$BAUD_RATE"
    fi
}

# Monitor serial output
monitor_serial() {
    echo "👁️  Monitoring serial output..."
    check_serial_device
    
    echo "🔌 Using serial device: $SERIAL_DEVICE at $BAUD_RATE baud"
    echo "⏱️  Monitoring for $BOOT_TIMEOUT seconds"
    echo "Press Ctrl+C to stop"
    echo ""
    
    if [ -f "$SCRIPT_DIR/serial_console/check_board_status.py" ]; then
        cd "$SCRIPT_DIR/serial_console"
        python3 check_board_status.py \
            --device "$SERIAL_DEVICE" \
            --baud "$BAUD_RATE" \
            --monitor "$BOOT_TIMEOUT"
    else
        echo "❌ Error: Board status script not found"
        echo "Falling back to screen..."
        timeout "$BOOT_TIMEOUT" screen "$SERIAL_DEVICE" "$BAUD_RATE" || true
    fi
}

# Interactive serial console
interactive_console() {
    echo "💬 Starting interactive serial console..."
    check_serial_device
    
    echo "🔌 Using serial device: $SERIAL_DEVICE at $BAUD_RATE baud"
    echo "💡 Use Ctrl+] to exit, Ctrl+L to toggle logging"
    echo ""
    
    if [ -f "$SCRIPT_DIR/serial_console/serial_console.py" ]; then
        cd "$SCRIPT_DIR/serial_console"
        python3 serial_console.py \
            --device "$SERIAL_DEVICE" \
            --baud "$BAUD_RATE" \
            --timestamps \
            --log "boot_dev_session_$(date +%Y%m%d_%H%M%S).log"
    else
        echo "❌ Error: Serial console script not found"
        echo "Falling back to screen..."
        screen "$SERIAL_DEVICE" "$BAUD_RATE"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        build-uboot|build-dtbs|build-boot|program-boot|test-boot|interactive|monitor|uboot-shell)
            ACTION="$1"
            shift
            ;;
        -m|--machine)
            MACHINE="$2"
            shift 2
            ;;
        -d|--device)
            SERIAL_DEVICE="$2"
            shift 2
            ;;
        -b|--baud)
            BAUD_RATE="$2"
            shift 2
            ;;
        -t|--timeout)
            BOOT_TIMEOUT="$2"
            shift 2
            ;;
        -c|--component)
            COMPONENT="$2"
            shift 2
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "❌ Error: Unknown option $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if action was provided
if [ -z "$ACTION" ]; then
    echo "❌ Error: No action specified"
    show_usage
    exit 1
fi

# Change to project root
cd "$PROJECT_ROOT"

echo "🎯 KAS Boot-Level Development - $ACTION"
echo "🎛️  Machine: $MACHINE"
if [[ "$ACTION" =~ (test-boot|interactive|monitor|uboot-shell) ]]; then
    echo "🔌 Serial: $SERIAL_DEVICE @ $BAUD_RATE baud"
fi

# Execute the requested action
case "$ACTION" in
    build-uboot)
        build_uboot
        ;;
    build-dtbs)
        build_dtbs
        ;;
    build-boot)
        build_boot
        ;;
    program-boot)
        program_boot
        ;;
    test-boot)
        test_boot
        ;;
    interactive)
        interactive_console
        ;;
    monitor)
        monitor_serial
        ;;
    uboot-shell)
        uboot_shell
        ;;
    *)
        echo "❌ Error: Unknown action: $ACTION"
        show_usage
        exit 1
        ;;
esac

echo "🎉 Action '$ACTION' completed successfully!"
