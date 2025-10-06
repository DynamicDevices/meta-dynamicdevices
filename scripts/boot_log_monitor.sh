#!/bin/bash
#
# Boot Log Monitor Script
#
# This script monitors the serial console boot output to capture and analyze
# the complete boot sequence. It can be used for any embedded system boot
# logging and verification purposes.
#
# Usage: ./boot_log_monitor.sh [options]
#
# Options:
#   -d, --device DEVICE     Serial device (default: /dev/ttyUSB1)
#   -b, --baud BAUD         Baud rate (default: 115200)
#   -t, --timeout TIMEOUT   Monitor timeout in seconds (default: 60)
#   -l, --log FILE          Save output to log file
#   -a, --analyze           Analyze boot log for common verification patterns
#   -h, --help              Show this help message
#
# Examples:
#   # Monitor with default settings
#   ./boot_log_monitor.sh
#
#   # Monitor and save to log file with analysis
#   ./boot_log_monitor.sh --log boot.log --analyze
#
#   # Monitor different serial device
#   ./boot_log_monitor.sh -d /dev/ttyUSB0 -b 9600
#
# Common Boot Verification Patterns Detected:
#   - Hash verification messages (SHA256, SHA1, etc.)
#   - Signature verification (RSA, ECDSA, etc.)
#   - Image loading and verification
#   - Boot stage transitions
#   - Error conditions and failures
#

set -euo pipefail

# Default values
SERIAL_DEVICE="/dev/ttyUSB1"
BAUD_RATE="115200"
TIMEOUT="60"
LOG_FILE=""
ANALYZE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to show usage
show_usage() {
    grep '^# Usage:' "$0" | cut -c 3-
    grep '^# Options:' "$0" | cut -c 3-
    grep '^# Examples:' "$0" | cut -c 3-
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--device)
            SERIAL_DEVICE="$2"
            shift 2
            ;;
        -b|--baud)
            BAUD_RATE="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
            ;;
        -a|--analyze)
            ANALYZE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if serial device exists
if [ ! -e "$SERIAL_DEVICE" ]; then
    echo -e "${RED}ERROR: Serial device $SERIAL_DEVICE not found${NC}"
    exit 1
fi

# Check if we have permission to access the serial device
if [ ! -r "$SERIAL_DEVICE" ] || [ ! -w "$SERIAL_DEVICE" ]; then
    echo -e "${RED}ERROR: No permission to access $SERIAL_DEVICE${NC}"
    echo "Try: sudo chmod 666 $SERIAL_DEVICE"
    exit 1
fi

echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}BOOT LOG MONITOR${NC}"
echo -e "${CYAN}============================================================${NC}"
echo -e "${BLUE}Device:${NC} $SERIAL_DEVICE"
echo -e "${BLUE}Baud Rate:${NC} $BAUD_RATE"
echo -e "${BLUE}Timeout:${NC} ${TIMEOUT}s"
if [ -n "$LOG_FILE" ]; then
    echo -e "${BLUE}Log File:${NC} $LOG_FILE"
fi
if [ "$ANALYZE" = true ]; then
    echo -e "${BLUE}Analysis:${NC} Enabled"
fi
echo ""
echo -e "${YELLOW}🔄 Reset/power cycle the board now to capture the boot sequence${NC}"
echo -e "${YELLOW}⏹️  Press Ctrl+C to stop monitoring${NC}"
echo ""
echo -e "${CYAN}------------------------------------------------------------${NC}"

# Configure the serial port
echo -e "${BLUE}📡 Configuring serial port...${NC}"
stty -F "$SERIAL_DEVICE" "$BAUD_RATE" cs8 -cstopb -parenb raw -echo

# Start monitoring
echo -e "${BLUE}📺 Monitoring serial output...${NC}"
echo ""

# Setup log file if specified
if [ -n "$LOG_FILE" ]; then
    # Monitor with logging
    timeout "$TIMEOUT" cat "$SERIAL_DEVICE" | tee "$LOG_FILE"
else
    # Monitor without logging
    timeout "$TIMEOUT" cat "$SERIAL_DEVICE"
fi

echo ""
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${GREEN}✅ Monitoring completed${NC}"

# Analyze the log if requested and log file exists
if [ "$ANALYZE" = true ] && [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
    echo -e "${BLUE}📋 Boot log saved to: $LOG_FILE${NC}"
    
    echo ""
    echo -e "${CYAN}🔍 BOOT LOG ANALYSIS:${NC}"
    
    # Check for various verification patterns
    HASH_VERIFICATIONS=$(grep -c "hash.*OK\|Hash.*OK\|Verifying.*OK" "$LOG_FILE" 2>/dev/null || echo "0")
    SIGNATURE_VERIFICATIONS=$(grep -c "signature.*OK\|rsa.*OK\|ecdsa.*OK" "$LOG_FILE" 2>/dev/null || echo "0")
    BOOT_STAGES=$(grep -c "U-Boot\|SPL\|Starting kernel\|Loading\|Booting" "$LOG_FILE" 2>/dev/null || echo "0")
    ERROR_COUNT=$(grep -c -i "error\|fail\|abort" "$LOG_FILE" 2>/dev/null || echo "0")
    
    echo -e "  ${BLUE}📊 Hash Verifications: $HASH_VERIFICATIONS${NC}"
    echo -e "  ${BLUE}📊 Signature Verifications: $SIGNATURE_VERIFICATIONS${NC}"
    echo -e "  ${BLUE}📊 Boot Stage Messages: $BOOT_STAGES${NC}"
    echo -e "  ${BLUE}📊 Error Messages: $ERROR_COUNT${NC}"
    
    # Check for specific verification messages
    if grep -q "Checking hash" "$LOG_FILE"; then
        echo -e "  ${GREEN}✅ Hash Checking: DETECTED${NC}"
    fi
    
    if grep -q "Verifying.*Integrity" "$LOG_FILE"; then
        echo -e "  ${GREEN}✅ Integrity Verification: DETECTED${NC}"
    fi
    
    if grep -q "sha256\|SHA256" "$LOG_FILE"; then
        echo -e "  ${GREEN}✅ SHA256 Hashing: DETECTED${NC}"
    fi
    
    if grep -q "rsa\|RSA" "$LOG_FILE"; then
        echo -e "  ${GREEN}✅ RSA Signatures: DETECTED${NC}"
    fi
    
    # Boot success check
    if grep -q "login:\|# \|$ " "$LOG_FILE"; then
        echo -e "  ${GREEN}✅ Boot Completion: SUCCESS${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Boot Completion: INCOMPLETE${NC}"
    fi
    
    # Overall assessment
    echo ""
    if [ "$ERROR_COUNT" -eq 0 ] && [ "$HASH_VERIFICATIONS" -gt 0 ]; then
        echo -e "${GREEN}🎯 BOOT STATUS: SUCCESSFUL WITH VERIFICATION${NC}"
    elif [ "$ERROR_COUNT" -eq 0 ]; then
        echo -e "${GREEN}✅ BOOT STATUS: SUCCESSFUL${NC}"
    else
        echo -e "${YELLOW}⚠️  BOOT STATUS: COMPLETED WITH ERRORS${NC}"
    fi
    
elif [ -n "$LOG_FILE" ]; then
    echo -e "${BLUE}📋 Boot log saved to: $LOG_FILE${NC}"
    echo -e "${BLUE}💡 Use --analyze flag to get detailed boot analysis${NC}"
fi

echo -e "${CYAN}============================================================${NC}"