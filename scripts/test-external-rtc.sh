#!/bin/bash
#
# External RTC Verification Script for imx93-jaguar-eink
# Tests PCF2131 RTC functionality on I2C3 @ 0x53
#

set -euo pipefail

echo "=============================================="
echo "External RTC Verification - PCF2131 @ I2C3"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test functions
test_passed() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
}

test_failed() {
    echo -e "${RED}❌ FAIL${NC}: $1"
}

test_info() {
    echo -e "${BLUE}ℹ️  INFO${NC}: $1"
}

test_warning() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
}

# Check if running on target board
if [ ! -f /proc/device-tree/model ]; then
    test_failed "Not running on target board - /proc/device-tree/model not found"
    exit 1
fi

BOARD_MODEL=$(cat /proc/device-tree/model 2>/dev/null || echo "Unknown")
echo "Board Model: $BOARD_MODEL"

if [[ ! "$BOARD_MODEL" =~ "imx93" ]]; then
    test_warning "Not running on imx93 board - some tests may not be applicable"
fi

echo ""
echo "1. Checking I2C3 Bus Availability..."
echo "======================================"

# Check if I2C3 bus exists
if [ ! -e /dev/i2c-3 ]; then
    test_failed "I2C3 bus not available (/dev/i2c-3 not found)"
    echo "Available I2C buses:"
    ls -la /dev/i2c-* 2>/dev/null || echo "No I2C buses found"
    exit 1
else
    test_passed "I2C3 bus available at /dev/i2c-3"
fi

echo ""
echo "2. Scanning I2C3 Bus for PCF2131 RTC..."
echo "======================================="

# Check if i2cdetect is available
if ! command -v i2cdetect &> /dev/null; then
    test_warning "i2cdetect not available - installing i2c-tools may be needed"
else
    echo "I2C3 bus scan:"
    i2cdetect -y 3 || test_warning "i2cdetect failed"
    
    # Check specifically for address 0x53
    if i2cdetect -y 3 | grep -q "53"; then
        test_passed "PCF2131 RTC detected at I2C address 0x53"
    else
        test_failed "PCF2131 RTC not detected at expected address 0x53"
    fi
fi

echo ""
echo "3. Checking RTC Driver and Device Node..."
echo "========================================="

# Check for RTC device nodes
RTC_DEVICES=$(ls /dev/rtc* 2>/dev/null || echo "")
if [ -z "$RTC_DEVICES" ]; then
    test_failed "No RTC devices found in /dev/"
else
    test_passed "RTC devices found:"
    for rtc in $RTC_DEVICES; do
        echo "  - $rtc"
    done
fi

# Check for PCF2131 in kernel logs
echo ""
echo "4. Checking Kernel Driver Loading..."
echo "===================================="

if dmesg | grep -i pcf2131 &>/dev/null; then
    test_passed "PCF2131 driver messages found in kernel log"
    echo "PCF2131 kernel messages:"
    dmesg | grep -i pcf2131 | tail -5
else
    test_warning "No PCF2131 driver messages found in kernel log"
fi

# Check for RTC driver in general
if dmesg | grep -i "rtc" &>/dev/null; then
    test_info "RTC-related kernel messages:"
    dmesg | grep -i rtc | tail -5
fi

echo ""
echo "5. Testing RTC Functionality..."
echo "==============================="

# Find the external RTC device
EXTERNAL_RTC=""
for rtc in /dev/rtc*; do
    if [ -e "$rtc" ]; then
        # Check if this RTC has the PCF2131 name
        RTC_NAME=$(cat /sys/class/rtc/$(basename $rtc)/name 2>/dev/null || echo "unknown")
        echo "  $rtc: $RTC_NAME"
        
        if [[ "$RTC_NAME" =~ "pcf2131" ]] || [[ "$RTC_NAME" =~ "2-0053" ]]; then
            EXTERNAL_RTC="$rtc"
            test_passed "Found external PCF2131 RTC at $rtc"
        fi
    fi
done

if [ -z "$EXTERNAL_RTC" ]; then
    test_warning "Could not identify external PCF2131 RTC device"
    # Use rtc0 as fallback
    if [ -e "/dev/rtc0" ]; then
        EXTERNAL_RTC="/dev/rtc0"
        test_info "Using /dev/rtc0 as fallback for testing"
    fi
fi

if [ -n "$EXTERNAL_RTC" ]; then
    echo ""
    echo "6. RTC Read/Write Test..."
    echo "========================"
    
    # Read current time
    if hwclock -r -f "$EXTERNAL_RTC" &>/dev/null; then
        CURRENT_TIME=$(hwclock -r -f "$EXTERNAL_RTC" 2>/dev/null)
        test_passed "Successfully read RTC time: $CURRENT_TIME"
    else
        test_failed "Could not read time from RTC $EXTERNAL_RTC"
    fi
    
    # Test write (set to system time)
    echo ""
    echo "Testing RTC write (setting to system time)..."
    if hwclock -w -f "$EXTERNAL_RTC" &>/dev/null; then
        test_passed "Successfully wrote system time to RTC"
        
        # Verify the write
        sleep 1
        NEW_TIME=$(hwclock -r -f "$EXTERNAL_RTC" 2>/dev/null || echo "Could not read")
        test_info "RTC time after write: $NEW_TIME"
    else
        test_failed "Could not write time to RTC $EXTERNAL_RTC"
    fi
fi

echo ""
echo "7. Power Management and Wake Features..."
echo "======================================="

# Check interrupt configuration
if [ -d "/proc/irq" ]; then
    echo "Checking for PCF2131 interrupt configuration..."
    # Look for GPIO4_IO22 interrupt (PCF2131 INTA#)
    if grep -r "pcf2131\|4-0053" /proc/interrupts 2>/dev/null; then
        test_passed "PCF2131 interrupt registered"
    else
        test_info "PCF2131 interrupt not found in /proc/interrupts (may be normal)"
    fi
fi

# Check wake capability
if [ -d "/sys/class/rtc" ]; then
    for rtc_sys in /sys/class/rtc/rtc*; do
        if [ -e "$rtc_sys/name" ]; then
            RTC_NAME=$(cat "$rtc_sys/name")
            if [[ "$RTC_NAME" =~ "pcf2131" ]] || [[ "$RTC_NAME" =~ "2-0053" ]]; then
                if [ -e "$rtc_sys/wakealarm" ]; then
                    test_passed "Wake alarm capability available for $RTC_NAME"
                else
                    test_warning "Wake alarm not available for $RTC_NAME"
                fi
            fi
        fi
    done
fi

echo ""
echo "8. System Time Synchronization..."
echo "================================"

# Check if systemd-timesyncd or similar is managing RTC sync
if systemctl is-active systemd-timesyncd &>/dev/null; then
    test_passed "systemd-timesyncd is active (handles RTC sync)"
elif systemctl is-active chronyd &>/dev/null; then
    test_passed "chronyd is active (handles RTC sync)"
elif systemctl is-active ntpd &>/dev/null; then
    test_passed "ntpd is active (handles RTC sync)"
else
    test_warning "No time synchronization service detected"
fi

echo ""
echo "=============================================="
echo "External RTC Verification Complete"
echo "=============================================="

# Summary
echo ""
echo "SUMMARY:"
echo "--------"
echo "• Board: $BOARD_MODEL"
echo "• Expected RTC: PCF2131 on I2C3 @ 0x53"
echo "• I2C3 Bus: $([ -e /dev/i2c-3 ] && echo "Available" || echo "Not Available")"
echo "• RTC Devices: $(ls /dev/rtc* 2>/dev/null | wc -l) found"
echo "• External RTC: ${EXTERNAL_RTC:-"Not identified"}"

echo ""
echo "NEXT STEPS:"
echo "-----------"
echo "1. If tests failed, check kernel config for PCF2131 support"
echo "2. Verify I2C3 pinmux configuration in device tree"
echo "3. Check hardware connections (SDA, SCL, power, interrupt)"
echo "4. Monitor kernel logs during boot: dmesg | grep -i rtc"
echo "5. Test wake functionality with: rtcwake -m mem -s 10"

echo ""
echo "For more details, run:"
echo "  cat /proc/interrupts | grep -i rtc"
echo "  cat /sys/class/rtc/*/name"
echo "  hwclock --show --verbose"
