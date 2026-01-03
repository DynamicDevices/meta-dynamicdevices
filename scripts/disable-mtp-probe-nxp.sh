#!/bin/bash

#
# Disable MTP Probe for NXP Devices
# 
# Prevents mtp-probe from interfering with NXP download mode devices
# This fixes USB disconnect issues during UUU programming
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

UDEV_RULE_FILE="/etc/udev/rules.d/60-disable-mtp-probe-nxp.rules"
RULE_CONTENT='# Disable MTP probe for NXP devices (i.MX download mode)
# Prevents mtp-probe from interfering with UUU programming
# NXP vendor ID: 1fc9
# This rule must run BEFORE 69-libmtp.rules (lower number = higher priority)
ACTION!="add", ACTION!="bind", GOTO="disable_mtp_nxp_end"
SUBSYSTEM!="usb", GOTO="disable_mtp_nxp_end"
ATTR{idVendor}=="1fc9", ENV{MTP_NO_PROBE}="1", GOTO="disable_mtp_nxp_end"
LABEL="disable_mtp_nxp_end"
'

echo "============================================================"
echo "Disable MTP Probe for NXP Devices"
echo "============================================================"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Check if rule already exists
if [[ -f "$UDEV_RULE_FILE" ]]; then
    if grep -q "MTP_NO_PROBE.*1fc9" "$UDEV_RULE_FILE" 2>/dev/null; then
        log_info "Rule already exists: $UDEV_RULE_FILE"
        log_info "Current rule content:"
        cat "$UDEV_RULE_FILE" | sed 's/^/  /'
        echo ""
        read -p "Overwrite existing rule? (y/N): " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            log_info "Keeping existing rule"
            exit 0
        fi
    fi
fi

# Create the udev rule
log_info "Creating udev rule: $UDEV_RULE_FILE"
echo "$RULE_CONTENT" > "$UDEV_RULE_FILE"
chmod 644 "$UDEV_RULE_FILE"

log_success "Udev rule created successfully"
echo ""

# Reload udev rules
log_info "Reloading udev rules..."
udevadm control --reload-rules
udevadm trigger

log_success "Udev rules reloaded"
echo ""

log_info "MTP probe is now disabled for NXP devices (vendor ID: 1fc9)"
log_info "This should prevent USB disconnects during UUU programming"
echo ""
log_info "To verify, check that MTP_NO_PROBE is set when device connects:"
log_info "  sudo udevadm info /sys/bus/usb/devices/3-2 | grep MTP_NO_PROBE"
echo ""
log_warn "Note: You may need to disconnect and reconnect your board"
log_warn "      for the new rule to take effect"


