#!/bin/bash
#
# Simple fix: Add NXP to MTP exclusion list
# This creates a rule that runs BEFORE 69-libmtp.rules and excludes NXP devices
#

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

echo "Adding NXP devices to MTP exclusion list..."

# Create rule with number 60- (runs before 69-libmtp.rules)
# This adds NXP to the exclusion list, preventing mtp-probe from running
cat > /etc/udev/rules.d/60-disable-mtp-probe-nxp.rules << 'EOF'
# Disable MTP probe for NXP devices (i.MX download mode)
# Prevents mtp-probe from interfering with UUU programming
# NXP vendor ID: 1fc9
# This rule runs BEFORE 69-libmtp.rules and excludes NXP from probing
ACTION!="add", ACTION!="bind", GOTO="disable_mtp_nxp_end"
SUBSYSTEM!="usb", GOTO="disable_mtp_nxp_end"
# Exclude NXP devices - same pattern as other sensitive devices in 69-libmtp.rules
ATTR{idVendor}=="1fc9", GOTO="disable_mtp_nxp_end"
LABEL="disable_mtp_nxp_end"
EOF

chmod 644 /etc/udev/rules.d/60-disable-mtp-probe-nxp.rules

# Also set MTP_NO_PROBE environment variable as backup
cat > /etc/udev/rules.d/61-set-mtp-no-probe-nxp.rules << 'EOF'
# Set MTP_NO_PROBE for NXP devices
ACTION!="add", ACTION!="bind", GOTO="set_mtp_no_probe_end"
SUBSYSTEM!="usb", GOTO="set_mtp_no_probe_end"
ATTR{idVendor}=="1fc9", ENV{MTP_NO_PROBE}="1"
LABEL="set_mtp_no_probe_end"
EOF

chmod 644 /etc/udev/rules.d/61-set-mtp-no-probe-nxp.rules

# Reload udev
echo "Reloading udev rules..."
udevadm control --reload-rules
udevadm trigger

echo ""
echo "Done! Created two rules:"
echo "  - 60-disable-mtp-probe-nxp.rules (excludes NXP from probe)"
echo "  - 61-set-mtp-no-probe-nxp.rules (sets MTP_NO_PROBE=1)"
echo ""
echo "Disconnect and reconnect your board for the change to take effect."



