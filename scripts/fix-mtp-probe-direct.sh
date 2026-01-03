#!/bin/bash
#
# Direct fix: Prevent mtp-probe PROGRAM execution for NXP devices
# This creates a rule that runs BEFORE 69-libmtp.rules
#

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

echo "Creating udev rule to prevent mtp-probe for NXP devices..."

# Remove old rules if they exist
rm -f /etc/udev/rules.d/60-disable-mtp-probe-nxp.rules
rm -f /etc/udev/rules.d/61-set-mtp-no-probe-nxp.rules
rm -f /etc/udev/rules.d/99-disable-mtp-probe-nxp.rules

# Create a rule that runs BEFORE 69-libmtp.rules (lower number = runs first)
# This sets MTP_NO_PROBE=1 for NXP devices, which the 69-libmtp.rules checks
cat > /etc/udev/rules.d/60-disable-mtp-probe-nxp.rules << 'EOF'
# Disable MTP probe for NXP devices (i.MX download mode)
# Prevents mtp-probe from interfering with UUU programming
# NXP vendor ID: 1fc9
# This rule MUST run before 69-libmtp.rules (lower number = higher priority)
ACTION=="add", ACTION=="bind", SUBSYSTEM=="usb", ATTR{idVendor}=="1fc9", ENV{MTP_NO_PROBE}="1"
EOF

chmod 644 /etc/udev/rules.d/60-disable-mtp-probe-nxp.rules

# Verify the rule file
echo ""
echo "Created rule file:"
cat /etc/udev/rules.d/60-disable-mtp-probe-nxp.rules
echo ""

# Reload udev
echo "Reloading udev rules..."
udevadm control --reload-rules
udevadm trigger --subsystem-match=usb

echo ""
echo "Done! The rule should now prevent mtp-probe from running on NXP devices."
echo ""
echo "To test:"
echo "  1. Disconnect your board"
echo "  2. Reconnect it in download mode"
echo "  3. Check logs: journalctl -f | grep mtp-probe"
echo "  4. You should NOT see mtp-probe checking NXP devices anymore"



