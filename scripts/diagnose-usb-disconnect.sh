#!/bin/bash

#
# USB Disconnect Diagnostic Script
# 
# Diagnoses USB device disconnect issues during UUU programming
#

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo "============================================================"
echo "USB Disconnect Diagnostic Tool"
echo "============================================================"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_warn "Not running as root - some checks may be limited"
    log_info "Consider running with sudo for full diagnostics"
    echo ""
fi

# 1. Check for NXP devices
log_info "Step 1: Checking for NXP USB devices..."
if command -v lsusb &> /dev/null; then
    nxp_devices=$(lsusb | grep -i "1fc9\|NXP\|Freescale" || true)
    if [[ -n "$nxp_devices" ]]; then
        log_success "Found NXP device(s):"
        echo "$nxp_devices" | sed 's/^/  /'
    else
        log_warn "No NXP devices currently detected"
        log_info "Connect your board in download mode and run this script again"
    fi
else
    log_error "lsusb not found - install usbutils package"
fi
echo ""

# 2. Monitor USB events
log_info "Step 2: Monitoring USB events (10 seconds)..."
log_info "Connect your board in download mode now..."
echo ""

# Monitor dmesg for USB events
timeout 10 dmesg -w 2>/dev/null | grep -i "usb.*1fc9\|usb.*disconnect" || true &
MONITOR_PID=$!

# Also check kernel ring buffer
log_info "Recent USB events from kernel log:"
dmesg | grep -i "usb.*1fc9\|usb.*disconnect" | tail -20 || log_warn "No recent USB events found"
echo ""

# Wait for monitor
sleep 10
kill $MONITOR_PID 2>/dev/null || true
echo ""

# 3. Check USB port power
log_info "Step 3: Checking USB port information..."
if [[ -d /sys/bus/usb/devices ]]; then
    for usb_dev in /sys/bus/usb/devices/*/idVendor; do
        if [[ -f "$usb_dev" ]]; then
            vendor=$(cat "$usb_dev" 2>/dev/null || echo "")
            if [[ "$vendor" == "1fc9" ]]; then
                dev_path=$(dirname "$usb_dev")
                log_success "Found NXP device at: $dev_path"
                
                # Check power
                if [[ -f "$dev_path/power/control" ]]; then
                    power_control=$(cat "$dev_path/power/control" 2>/dev/null || echo "unknown")
                    echo "  Power control: $power_control"
                fi
                
                # Check speed
                if [[ -f "$dev_path/speed" ]]; then
                    speed=$(cat "$dev_path/speed" 2>/dev/null || echo "unknown")
                    case "$speed" in
                        12) speed_str="USB 1.1 (12 Mbps)" ;;
                        480) speed_str="USB 2.0 (480 Mbps)" ;;
                        5000) speed_str="USB 3.0 (5 Gbps)" ;;
                        *) speed_str="Unknown ($speed)" ;;
                    esac
                    echo "  USB Speed: $speed_str"
                fi
                
                # Check if device is still connected
                if [[ -d "$dev_path" ]]; then
                    log_success "Device is currently connected"
                else
                    log_error "Device disconnected during check"
                fi
            fi
        fi
    done
else
    log_warn "Cannot access USB device information (need root access)"
fi
echo ""

# 4. Check udev rules
log_info "Step 4: Checking udev rules for USB devices..."
if [[ -d /etc/udev/rules.d ]]; then
    usb_rules=$(grep -r "1fc9\|NXP\|Freescale" /etc/udev/rules.d/ 2>/dev/null || true)
    if [[ -n "$usb_rules" ]]; then
        log_info "Found udev rules:"
        echo "$usb_rules" | sed 's/^/  /'
    else
        log_info "No specific udev rules found for NXP devices"
    fi
    
    # Check for MTP probe disable rule
    if [[ -f /etc/udev/rules.d/99-disable-mtp-probe-nxp.rules ]]; then
        log_success "MTP probe disable rule found for NXP devices"
    else
        log_warn "MTP probe may be interfering with NXP devices"
        log_info "Run: sudo ./scripts/disable-mtp-probe-nxp.sh to fix"
    fi
else
    log_warn "Cannot check udev rules (need root access)"
fi
echo ""

# 4.5. Check for mtp-probe interference
log_info "Step 4.5: Checking for mtp-probe interference..."
if dmesg | grep -q "mtp-probe.*1fc9\|mtp-probe.*NXP" 2>/dev/null; then
    log_warn "mtp-probe has been checking NXP devices"
    log_warn "This may cause USB disconnects during programming"
    log_info "Solution: Run 'sudo ./scripts/disable-mtp-probe-nxp.sh'"
else
    log_info "No recent mtp-probe activity on NXP devices"
fi
echo ""

# 5. Check USB subsystem
log_info "Step 5: Checking USB subsystem status..."
if command -v usb-devices &> /dev/null; then
    nxp_info=$(usb-devices | grep -A 20 "1fc9" || true)
    if [[ -n "$nxp_info" ]]; then
        log_success "USB device information:"
        echo "$nxp_info" | sed 's/^/  /'
    fi
fi
echo ""

# 6. Recommendations
log_info "Step 6: Recommendations..."
echo ""
echo "If device disconnects immediately:"
echo "  1. ✅ Try USB 2.0 port (more stable than USB 3.0)"
echo "  2. ✅ Use high-quality USB-C data cable (not charge-only)"
echo "  3. ✅ Try powered USB hub if port power is insufficient"
echo "  4. ✅ Verify boot mode switches are correctly set"
echo "  5. ✅ Start UUU BEFORE connecting board, or immediately after"
echo "  6. ✅ Try different USB port on computer"
echo "  7. ✅ Check board power supply (needs 5V 2A minimum)"
echo ""
echo "Quick test:"
echo "  sudo dmesg -w | grep -i usb"
echo "  # Then connect board and watch for disconnect messages"
echo ""

# 7. UUU readiness check
log_info "Step 7: Checking UUU tool availability..."
if command -v uuu &> /dev/null; then
    uuu_version=$(uuu -v 2>&1 | head -1 || echo "unknown")
    log_success "UUU tool found: $uuu_version"
else
    log_warn "UUU tool not in PATH"
    log_info "Use build-specific UUU from mfgtool-files package"
fi
echo ""

log_info "Diagnostic complete!"
log_info "If device keeps disconnecting, try the recommendations above"

