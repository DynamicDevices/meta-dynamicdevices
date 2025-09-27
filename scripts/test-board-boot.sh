#!/bin/bash
#
# Wrapper script for testing i.MX93 Jaguar E-Ink board boot process
# Provides easy access to the serial console testing tools
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERIAL_CONSOLE_DIR="$SCRIPT_DIR/serial_console"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

show_usage() {
    cat << EOF
Usage: $0 [command] [options]

Commands:
  status          - Quick board status check
  boot-test       - Full boot process test
  console         - Interactive serial console
  monitor         - Monitor serial output
  help            - Show this help

Options:
  -d DEVICE       - Serial device (default: /dev/ttyUSB1)
  -b BAUD         - Baud rate (default: 115200)
  -t TIMEOUT      - Timeout in seconds
  -l LOGFILE      - Log file name

Examples:
  $0 status                    # Quick status check
  $0 boot-test                 # Full boot test
  $0 boot-test -t 180          # Boot test with 3 minute timeout
  $0 console                   # Interactive console
  $0 monitor 30                # Monitor for 30 seconds
  $0 status -d /dev/ttyUSB0    # Use different serial device

After programming the board:
  1. Change boot pins from programming mode to boot mode
  2. Run: $0 status
  3. If responsive, run: $0 boot-test
EOF
}

# Check if pyserial is installed
check_dependencies() {
    if ! python3 -c "import serial" 2>/dev/null; then
        print_error "pyserial is not installed"
        print_status "Installing pyserial..."
        pip3 install pyserial || {
            print_error "Failed to install pyserial"
            print_status "Try: sudo apt install python3-serial"
            exit 1
        }
    fi
}

# Parse command line arguments
COMMAND=""
DEVICE=""
BAUD=""
TIMEOUT=""
LOGFILE=""
MONITOR_TIME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        status|boot-test|console|monitor|help)
            if [[ -z "$COMMAND" ]]; then
                COMMAND="$1"
                if [[ "$COMMAND" == "monitor" && "$2" =~ ^[0-9]+$ ]]; then
                    MONITOR_TIME="$2"
                    shift
                fi
            else
                print_error "Multiple commands specified"
                exit 1
            fi
            ;;
        -d|--device)
            DEVICE="$2"
            shift
            ;;
        -b|--baud)
            BAUD="$2"
            shift
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift
            ;;
        -l|--log)
            LOGFILE="$2"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
    shift
done

# Default command
if [[ -z "$COMMAND" ]]; then
    COMMAND="help"
fi

# Show help
if [[ "$COMMAND" == "help" ]]; then
    show_usage
    exit 0
fi

# Check dependencies
check_dependencies

# Build command arguments
ARGS=()
if [[ -n "$DEVICE" ]]; then
    ARGS+=("-d" "$DEVICE")
fi
if [[ -n "$BAUD" ]]; then
    ARGS+=("-b" "$BAUD")
fi

# Execute command
case "$COMMAND" in
    status)
        print_header "=== i.MX93 Board Status Check ==="
        print_status "Checking board status via serial console..."
        python3 "$SERIAL_CONSOLE_DIR/check_board_status.py" "${ARGS[@]}"
        ;;
    
    boot-test)
        print_header "=== i.MX93 Boot Process Test ==="
        print_status "Testing complete boot process..."
        
        if [[ -n "$TIMEOUT" ]]; then
            ARGS+=("-t" "$TIMEOUT")
        fi
        
        python3 "$SERIAL_CONSOLE_DIR/test_boot_process.py" "${ARGS[@]}"
        ;;
    
    console)
        print_header "=== i.MX93 Interactive Serial Console ==="
        print_status "Starting interactive console..."
        print_status "Press Ctrl+] to exit, Ctrl+L to toggle logging"
        
        if [[ -n "$LOGFILE" ]]; then
            ARGS+=("-l" "$LOGFILE")
        fi
        
        python3 "$SERIAL_CONSOLE_DIR/serial_console.py" "${ARGS[@]}"
        ;;
    
    monitor)
        print_header "=== i.MX93 Serial Monitor ==="
        
        if [[ -z "$MONITOR_TIME" ]]; then
            MONITOR_TIME="30"
        fi
        
        print_status "Monitoring serial output for $MONITOR_TIME seconds..."
        python3 "$SERIAL_CONSOLE_DIR/check_board_status.py" "${ARGS[@]}" --monitor "$MONITOR_TIME"
        ;;
    
    *)
        print_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac
