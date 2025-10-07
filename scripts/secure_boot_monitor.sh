#!/bin/bash
#
# i.MX93 Secure Boot Monitor Script
#
# This script monitors the serial console boot output to verify secure boot
# signature verification is working correctly. It captures the complete boot
# sequence including SPL, U-Boot, and kernel verification messages.
#
# Usage: ./secure_boot_monitor.sh [options]
#
# Options:
#   -d, --device DEVICE     Serial device (default: /dev/ttyUSB1)
#   -b, --baud BAUD         Baud rate (default: 115200)
#   -t, --timeout TIMEOUT   Monitor timeout in seconds (default: 60)
#   -l, --log FILE          Save output to log file
#   -h, --help              Show this help message
#
# Examples:
#   # Monitor with default settings
#   ./secure_boot_monitor.sh
#
#   # Monitor and save to log file
#   ./secure_boot_monitor.sh --log boot_verification.log
#
#   # Monitor different serial device
#   ./secure_boot_monitor.sh -d /dev/ttyUSB0
#
# Expected Secure Boot Verification Messages:
#   - SPL: "## Checking hash(es) for config config-1 ... sha256,rsa2048:spldev+ OK"
#   - U-Boot: "Verifying Hash Integrity ... sha256,rsa2048:ubootdev+ OK"
#   - Kernel: "Verifying Hash Integrity ... sha256+ OK"
#   - Ramdisk: "Verifying Hash Integrity ... sha256+ OK"
#   - Device Tree: "Verifying Hash Integrity ... sha256+ OK"
#

set -euo pipefail

# Default values
SERIAL_DEVICE="/dev/ttyUSB1"
BAUD_RATE="115200"
TIMEOUT="60"
LOG_FILE=""
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
echo -e "${CYAN}i.MX93 SECURE BOOT MONITOR${NC}"
echo -e "${CYAN}============================================================${NC}"
echo -e "${BLUE}Device:${NC} $SERIAL_DEVICE"
echo -e "${BLUE}Baud Rate:${NC} $BAUD_RATE"
echo -e "${BLUE}Timeout:${NC} ${TIMEOUT}s"
if [ -n "$LOG_FILE" ]; then
    echo -e "${BLUE}Log File:${NC} $LOG_FILE"
fi
echo ""
echo -e "${YELLOW}🔄 Reset/power cycle the board now to see the secure boot sequence${NC}"
echo -e "${YELLOW}⏹️  Press Ctrl+C to stop monitoring${NC}"
echo ""
echo -e "${GREEN}Expected Secure Boot Verification Messages:${NC}"
echo -e "  ${GREEN}✓${NC} SPL: ## Checking hash(es) for config config-1 ... sha256,rsa2048:spldev+ OK"
echo -e "  ${GREEN}✓${NC} U-Boot: Verifying Hash Integrity ... sha256,rsa2048:ubootdev+ OK"
echo -e "  ${GREEN}✓${NC} Kernel: Verifying Hash Integrity ... sha256+ OK"
echo -e "  ${GREEN}✓${NC} Ramdisk: Verifying Hash Integrity ... sha256+ OK"
echo -e "  ${GREEN}✓${NC} Device Tree: Verifying Hash Integrity ... sha256+ OK"
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

if [ -n "$LOG_FILE" ]; then
    echo -e "${BLUE}📋 Boot log saved to: $LOG_FILE${NC}"
    
    # Analyze the log for secure boot verification
    echo ""
    echo -e "${CYAN}🔍 SECURE BOOT VERIFICATION ANALYSIS:${NC}"
    
    if grep -q "## Checking hash(es) for config config-1.*OK" "$LOG_FILE"; then
        echo -e "  ${GREEN}✅ SPL Configuration Verification: PASSED${NC}"
    else
        echo -e "  ${RED}❌ SPL Configuration Verification: NOT FOUND${NC}"
    fi
    
    if grep -q "Verifying Hash Integrity.*sha256,rsa2048.*OK" "$LOG_FILE"; then
        echo -e "  ${GREEN}✅ RSA2048 Signature Verification: PASSED${NC}"
    else
        echo -e "  ${RED}❌ RSA2048 Signature Verification: NOT FOUND${NC}"
    fi
    
    if grep -q "Verifying Hash Integrity.*sha256.*OK" "$LOG_FILE"; then
        echo -e "  ${GREEN}✅ SHA256 Hash Verification: PASSED${NC}"
    else
        echo -e "  ${RED}❌ SHA256 Hash Verification: NOT FOUND${NC}"
    fi
    
    VERIFICATION_COUNT=$(grep -c "Verifying Hash Integrity.*OK" "$LOG_FILE" || echo "0")
    echo -e "  ${BLUE}📊 Total Verifications: $VERIFICATION_COUNT${NC}"
    
    if [ "$VERIFICATION_COUNT" -ge 3 ]; then
        echo ""
        echo -e "${GREEN}🔒 SECURE BOOT STATUS: FULLY OPERATIONAL${NC}"
    else
        echo ""
        echo -e "${YELLOW}⚠️  SECURE BOOT STATUS: INCOMPLETE VERIFICATION${NC}"
    fi
fi

echo -e "${CYAN}============================================================${NC}"
