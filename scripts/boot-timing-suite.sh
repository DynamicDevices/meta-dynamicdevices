#!/bin/bash
# Boot Timing Suite - Complete boot analysis workflow
# Usage: ./boot-timing-suite.sh [command] [options]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

show_help() {
    cat << EOF
Boot Timing Suite for Dynamic Devices Boards

COMMANDS:
    capture [options]       Capture boot log over serial
    analyze [options]       Analyze captured boot logs
    compare                 Compare multiple boot logs
    latest                  Analyze the most recent boot log
    monitor                 Continuous boot monitoring
    help                    Show this help

CAPTURE OPTIONS:
    --device DEVICE         Serial device (default: /dev/ttyUSB1)
    --baudrate RATE         Baud rate (default: 115200)
    --timeout SECONDS       Capture timeout (default: 120)
    --name NAME             Board name for logs

ANALYZE OPTIONS:
    --log-dir DIR           Directory containing logs
    --output-dir DIR        Analysis output directory

EXAMPLES:
    # Complete workflow - capture and analyze
    $0 capture --name imx93-test
    $0 latest

    # Custom serial device
    $0 capture --device /dev/ttyUSB0 --name board-v2

    # Analyze specific log
    $0 analyze ./boot-logs/boot_20240115_143022_timing.log

    # Compare all captured logs
    $0 compare

    # Monitor boot times over multiple reboots
    $0 monitor

WORKFLOW:
    1. Connect serial cable to board
    2. Run: $0 capture --name your-board-name
    3. Power cycle or reset the board
    4. Wait for boot to complete (or timeout)
    5. Run: $0 latest (to analyze most recent log)
    6. Review analysis and optimization recommendations

EOF
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for required tools
    command -v bc >/dev/null 2>&1 || missing_deps+=("bc")
    command -v stty >/dev/null 2>&1 || missing_deps+=("stty")
    command -v timeout >/dev/null 2>&1 || missing_deps+=("timeout")
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}"
        echo "Install with: sudo apt-get install ${missing_deps[*]}"
        exit 1
    fi
}

# Check serial device permissions
check_serial_permissions() {
    local device="${1:-/dev/ttyUSB1}"
    
    if [[ ! -e "$device" ]]; then
        echo "Warning: Serial device $device not found"
        echo "Available devices:"
        ls -la /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || echo "  No USB serial devices found"
        return 1
    fi
    
    if [[ ! -r "$device" || ! -w "$device" ]]; then
        echo "Warning: No read/write access to $device"
        echo "Fix with one of:"
        echo "  sudo chmod 666 $device"
        echo "  sudo usermod -a -G dialout $USER  (then logout/login)"
        return 1
    fi
    
    return 0
}

# Capture boot log
cmd_capture() {
    echo "=== Boot Log Capture ==="
    check_dependencies
    
    # Default device check
    local device="/dev/ttyUSB1"
    for arg in "$@"; do
        if [[ "$prev_arg" == "--device" ]]; then
            device="$arg"
        fi
        prev_arg="$arg"
    done
    
    check_serial_permissions "$device" || echo "Continuing anyway..."
    
    echo "Starting serial boot logger..."
    exec "$SCRIPT_DIR/serial-boot-logger.sh" "$@"
}

# Analyze boot logs
cmd_analyze() {
    echo "=== Boot Log Analysis ==="
    exec "$SCRIPT_DIR/analyze-boot-logs.sh" "$@"
}

# Analyze latest log
cmd_latest() {
    echo "=== Latest Boot Analysis ==="
    exec "$SCRIPT_DIR/analyze-boot-logs.sh" --latest "$@"
}

# Compare logs
cmd_compare() {
    echo "=== Boot Log Comparison ==="
    exec "$SCRIPT_DIR/analyze-boot-logs.sh" --compare "$@"
}

# Continuous monitoring
cmd_monitor() {
    echo "=== Continuous Boot Monitoring ==="
    echo "This will capture multiple boot cycles for trend analysis"
    echo "Press Ctrl+C to stop monitoring"
    echo ""
    
    local count=1
    while true; do
        echo "=== Boot Capture #$count ==="
        echo "Power cycle the board now..."
        
        # Capture with automatic naming
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        "$SCRIPT_DIR/serial-boot-logger.sh" --name "monitor_${count}_${timestamp}" --timeout 180 "$@"
        
        echo ""
        echo "Boot #$count complete. Analysis:"
        "$SCRIPT_DIR/analyze-boot-logs.sh" --latest
        
        echo ""
        echo "Press Enter for next capture, or Ctrl+C to stop..."
        read -r
        
        ((count++))
    done
}

# Show status and quick help
cmd_status() {
    echo "=== Boot Timing Suite Status ==="
    echo ""
    
    # Check tools
    echo "Tools:"
    [[ -x "$SCRIPT_DIR/serial-boot-logger.sh" ]] && echo "  ✅ Serial logger ready" || echo "  ❌ Serial logger missing"
    [[ -x "$SCRIPT_DIR/analyze-boot-logs.sh" ]] && echo "  ✅ Log analyzer ready" || echo "  ❌ Log analyzer missing"
    
    # Check dependencies
    echo ""
    echo "Dependencies:"
    command -v bc >/dev/null 2>&1 && echo "  ✅ bc available" || echo "  ❌ bc missing"
    command -v stty >/dev/null 2>&1 && echo "  ✅ stty available" || echo "  ❌ stty missing"
    command -v timeout >/dev/null 2>&1 && echo "  ✅ timeout available" || echo "  ❌ timeout missing"
    
    # Check serial devices
    echo ""
    echo "Serial devices:"
    if ls /dev/ttyUSB* /dev/ttyACM* >/dev/null 2>&1; then
        for dev in /dev/ttyUSB* /dev/ttyACM*; do
            [[ -e "$dev" ]] || continue
            if [[ -r "$dev" && -w "$dev" ]]; then
                echo "  ✅ $dev (accessible)"
            else
                echo "  ⚠️  $dev (no permissions)"
            fi
        done
    else
        echo "  ❌ No USB serial devices found"
    fi
    
    # Check existing logs
    echo ""
    echo "Existing logs:"
    local log_count=$(find ./boot-logs -name "*_timing.log" 2>/dev/null | wc -l)
    echo "  Found $log_count timing logs in ./boot-logs/"
    
    if [[ $log_count -gt 0 ]]; then
        echo "  Latest: $(find ./boot-logs -name "*_timing.log" 2>/dev/null | sort | tail -1 | xargs basename)"
    fi
    
    echo ""
    echo "Quick start:"
    echo "  1. $0 capture --name my-board"
    echo "  2. Power cycle board"
    echo "  3. $0 latest"
}

# Main command dispatch
case "${1:-help}" in
    capture)
        shift
        cmd_capture "$@"
        ;;
    analyze)
        shift
        cmd_analyze "$@"
        ;;
    latest)
        shift
        cmd_latest "$@"
        ;;
    compare)
        shift
        cmd_compare "$@"
        ;;
    monitor)
        shift
        cmd_monitor "$@"
        ;;
    status)
        cmd_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac
