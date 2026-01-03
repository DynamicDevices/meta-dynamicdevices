#!/bin/bash
#
# Final fix: Set MTP_NO_PROBE for NXP devices with correct udev syntax
#

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

echo "Creating udev rule to disable mtp-probe for NXP devices..."

# Remove any old rules
rm -f /etc/udev/rules.d/*-disable-mtp-probe-nxp.rules
rm -f /etc/udev/rules.d/*-set-mtp-no-probe-nxp.rules

# Create rule with correct syntax - must match BEFORE 69-libmtp.rules processes
# The key is to set MTP_NO_PROBE=1 for NXP vendor ID 1fc9
cat > /etc/udev/rules.d/60-disable-mtp-probe-nxp.rules << 'EOF'
# Disable MTP probe for NXP devices (i.MX download mode)
# NXP vendor ID: 1fc9
# This rule runs BEFORE 69-libmtp.rules and sets MTP_NO_PROBE=1
# The 69-libmtp.rules checks ENV{MTP_NO_PROBE}!="1" before running probe
SUBSYSTEM=="usb", ATTR{idVendor}=="1fc9", ENV{MTP_NO_PROBE}="1"
EOF

chmod 644 /etc/udev/rules.d/60-disable-mtp-probe-nxp.rules

echo "Rule created:"
cat /etc/udev/rules.d/60-disable-mtp-probe-nxp.rules
echo ""

# Reload udev
echo "Reloading udev rules..."
udevadm control --reload-rules
udevadm trigger --subsystem-match=usb --action=add

echo ""
echo "Done! Disconnect and reconnect your board to test."
echo "Check logs with: journalctl -f | grep -E 'mtp-probe|1fc9'"



