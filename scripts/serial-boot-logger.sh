#!/bin/bash
# Serial Boot Logger for Dynamic Devices Boards
# Captures boot timing data over serial port before networking is available
# Usage: ./serial-boot-logger.sh [--device /dev/ttyUSB1] [--baudrate 115200] [--timeout 120]

set -e

# Default configuration
DEFAULT_DEVICE="/dev/ttyUSB1"
DEFAULT_BAUDRATE="115200"
DEFAULT_TIMEOUT="120"  # 2 minutes timeout
DEFAULT_LOG_DIR="./boot-logs"

# Parse command line arguments
DEVICE="$DEFAULT_DEVICE"
BAUDRATE="$DEFAULT_BAUDRATE"
TIMEOUT="$DEFAULT_TIMEOUT"
LOG_DIR="$DEFAULT_LOG_DIR"
BOARD_NAME=""

show_help() {
    cat << EOF
Serial Boot Logger for Dynamic Devices Boards

Usage: $0 [OPTIONS]

OPTIONS:
    -d, --device DEVICE     Serial device (default: $DEFAULT_DEVICE)
    -b, --baudrate RATE     Baud rate (default: $DEFAULT_BAUDRATE)
    -t, --timeout SECONDS   Timeout in seconds (default: $DEFAULT_TIMEOUT)
    -l, --log-dir DIR       Log directory (default: $DEFAULT_LOG_DIR)
    -n, --name NAME         Board name for log file prefix
    -h, --help              Show this help

EXAMPLES:
    # Basic usage with defaults
    $0

    # Custom serial device
    $0 --device /dev/ttyUSB0

    # Custom timeout and board name
    $0 --timeout 180 --name imx93-eink-test

    # Full custom configuration
    $0 -d /dev/ttyUSB0 -b 115200 -t 300 -l ./my-logs -n board-v2

The script will:
1. Check serial device availability
2. Create timestamped log files
3. Capture boot output with timestamps
4. Detect boot completion markers
5. Generate timing analysis report
6. Save raw and analyzed logs

Boot completion is detected by looking for:
- Login prompt
- Systemd startup completion
- Network interface up
- SSH service ready

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--device)
            DEVICE="$2"
            shift 2
            ;;
        -b|--baudrate)
            BAUDRATE="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -l|--log-dir)
            LOG_DIR="$2"
            shift 2
            ;;
        -n|--name)
            BOARD_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate serial device
if [[ ! -e "$DEVICE" ]]; then
    echo "Error: Serial device $DEVICE not found"
    echo "Available devices:"
    ls -la /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || echo "  No USB serial devices found"
    exit 1
fi

if [[ ! -r "$DEVICE" || ! -w "$DEVICE" ]]; then
    echo "Error: No read/write access to $DEVICE"
    echo "Try: sudo chmod 666 $DEVICE"
    echo "Or add user to dialout group: sudo usermod -a -G dialout $USER"
    exit 1
fi

# Create log directory
mkdir -p "$LOG_DIR"

# Generate log file names
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
if [[ -n "$BOARD_NAME" ]]; then
    LOG_PREFIX="${BOARD_NAME}_${TIMESTAMP}"
else
    LOG_PREFIX="boot_${TIMESTAMP}"
fi

RAW_LOG="${LOG_DIR}/${LOG_PREFIX}_raw.log"
TIMING_LOG="${LOG_DIR}/${LOG_PREFIX}_timing.log"
ANALYSIS_LOG="${LOG_DIR}/${LOG_PREFIX}_analysis.txt"

echo "=== Serial Boot Logger Starting ==="
echo "Device: $DEVICE"
echo "Baudrate: $BAUDRATE"
echo "Timeout: ${TIMEOUT}s"
echo "Log directory: $LOG_DIR"
echo "Log prefix: $LOG_PREFIX"
echo ""
echo "Raw log: $RAW_LOG"
echo "Timing log: $TIMING_LOG"
echo "Analysis: $ANALYSIS_LOG"
echo ""

# Configure serial port (using stty for maximum compatibility)
echo "Configuring serial port..."
stty -F "$DEVICE" "$BAUDRATE" cs8 -cstopb -parenb -echo -echoe -echok -echoctl -echoke -icanon -isig -iexten -ixon -ixoff -icrnl -onlcr

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "=== Boot logging stopped ==="
    if [[ -f "$RAW_LOG" ]]; then
        echo "Raw log saved: $RAW_LOG ($(wc -l < "$RAW_LOG") lines)"
    fi
    if [[ -f "$TIMING_LOG" ]]; then
        echo "Timing log saved: $TIMING_LOG ($(wc -l < "$TIMING_LOG") lines)"
    fi
    if [[ -f "$ANALYSIS_LOG" ]]; then
        echo "Analysis saved: $ANALYSIS_LOG"
        echo ""
        echo "=== Quick Analysis ==="
        cat "$ANALYSIS_LOG"
    fi
}

trap cleanup EXIT INT TERM

# Start logging with timestamps
echo "=== Starting boot capture (timeout: ${TIMEOUT}s) ==="
echo "Press Ctrl+C to stop logging"
echo "Waiting for boot output on $DEVICE..."
echo ""

# Record start time
START_TIME=$(date +%s.%N)
echo "Boot logging started at: $(date)" > "$TIMING_LOG"
echo "Start timestamp: $START_TIME" >> "$TIMING_LOG"
echo "" >> "$TIMING_LOG"

# Use timeout and cat for simple, reliable serial reading
# This avoids complex terminal handling that has caused issues before
timeout "$TIMEOUT" cat "$DEVICE" | while IFS= read -r line; do
    # Get current timestamp
    CURRENT_TIME=$(date +%s.%N)
    RELATIVE_TIME=$(echo "$CURRENT_TIME - $START_TIME" | bc -l)
    FORMATTED_TIME=$(printf "%.3f" "$RELATIVE_TIME")
    
    # Write to raw log (original output)
    echo "$line" >> "$RAW_LOG"
    
    # Write to timing log (with timestamps)
    echo "[$FORMATTED_TIME] $line" >> "$TIMING_LOG"
    
    # Display with timestamp (optional - can be noisy)
    echo "[$FORMATTED_TIME] $line"
    
    # Check for boot completion markers
    if echo "$line" | grep -q -E "(login:|systemd.*Startup finished|eth0.*up|sshd.*started|Welcome to|~#|root@)"; then
        echo "" >> "$TIMING_LOG"
        echo "Boot completion marker detected at $FORMATTED_TIME: $line" >> "$TIMING_LOG"
        echo "Boot completion detected at ${FORMATTED_TIME}s" >&2
    fi
done

# Generate analysis report
echo "=== Generating Boot Analysis ===" >&2

cat > "$ANALYSIS_LOG" << EOF
=== Boot Timing Analysis ===
Generated: $(date)
Board: ${BOARD_NAME:-Unknown}
Device: $DEVICE
Baudrate: $BAUDRATE

=== Boot Markers Found ===
EOF

# Extract key timing markers from the timing log
if [[ -f "$TIMING_LOG" ]]; then
    echo "Analyzing timing markers..." >&2
    
    # U-Boot markers
    grep -E "\[.*\].*U-Boot" "$TIMING_LOG" | head -5 >> "$ANALYSIS_LOG" 2>/dev/null || true
    
    # Kernel markers
    echo "" >> "$ANALYSIS_LOG"
    echo "=== Kernel Boot ===" >> "$ANALYSIS_LOG"
    grep -E "\[.*\].*Linux version" "$TIMING_LOG" | head -1 >> "$ANALYSIS_LOG" 2>/dev/null || true
    grep -E "\[.*\].*Freeing unused kernel" "$TIMING_LOG" | head -1 >> "$ANALYSIS_LOG" 2>/dev/null || true
    
    # Systemd markers
    echo "" >> "$ANALYSIS_LOG"
    echo "=== Systemd Boot ===" >> "$ANALYSIS_LOG"
    grep -E "\[.*\].*systemd.*Startup finished" "$TIMING_LOG" | head -1 >> "$ANALYSIS_LOG" 2>/dev/null || true
    
    # Login markers
    echo "" >> "$ANALYSIS_LOG"
    echo "=== Login Ready ===" >> "$ANALYSIS_LOG"
    grep -E "\[.*\].*(login:|Welcome to|root@)" "$TIMING_LOG" | head -3 >> "$ANALYSIS_LOG" 2>/dev/null || true
    
    # Calculate approximate boot time
    LAST_MARKER=$(grep -E "\[.*\].*(login:|Welcome to|systemd.*Startup finished)" "$TIMING_LOG" | tail -1 | sed -E 's/.*\[([0-9.]+)\].*/\1/' 2>/dev/null || echo "")
    
    echo "" >> "$ANALYSIS_LOG"
    echo "=== Boot Time Summary ===" >> "$ANALYSIS_LOG"
    if [[ -n "$LAST_MARKER" ]]; then
        echo "Approximate boot time: ${LAST_MARKER}s" >> "$ANALYSIS_LOG"
        
        # Compare to targets
        if (( $(echo "$LAST_MARKER < 1.5" | bc -l) )); then
            echo "Status: ✅ EXCELLENT - Under 1.5s target" >> "$ANALYSIS_LOG"
        elif (( $(echo "$LAST_MARKER < 2.0" | bc -l) )); then
            echo "Status: ✅ GOOD - Under 2.0s target" >> "$ANALYSIS_LOG"
        elif (( $(echo "$LAST_MARKER < 5.0" | bc -l) )); then
            echo "Status: ⚠️  ACCEPTABLE - Under 5.0s" >> "$ANALYSIS_LOG"
        else
            echo "Status: ❌ SLOW - Over 5.0s, needs optimization" >> "$ANALYSIS_LOG"
        fi
    else
        echo "Boot time: Could not determine (no clear boot completion marker)" >> "$ANALYSIS_LOG"
    fi
    
    # Line counts
    RAW_LINES=$(wc -l < "$RAW_LOG" 2>/dev/null || echo "0")
    TIMING_LINES=$(wc -l < "$TIMING_LOG" 2>/dev/null || echo "0")
    
    echo "" >> "$ANALYSIS_LOG"
    echo "=== Log Statistics ===" >> "$ANALYSIS_LOG"
    echo "Raw log lines: $RAW_LINES" >> "$ANALYSIS_LOG"
    echo "Timing log lines: $TIMING_LINES" >> "$ANALYSIS_LOG"
    echo "Log files:" >> "$ANALYSIS_LOG"
    echo "  Raw: $RAW_LOG" >> "$ANALYSIS_LOG"
    echo "  Timing: $TIMING_LOG" >> "$ANALYSIS_LOG"
    echo "  Analysis: $ANALYSIS_LOG" >> "$ANALYSIS_LOG"
fi

echo "Analysis complete." >&2
