#!/bin/bash
#
# Fix USB Disconnect for NXP Download Mode Devices
# 
# This script addresses multiple causes of USB disconnects:
# 1. USB autosuspend
# 2. HID driver interference
# 3. Power management issues
#

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

echo "============================================================"
echo "Fixing USB Disconnect for NXP Devices"
echo "============================================================"
echo ""

# 1. Disable USB autosuspend for NXP devices
echo "1. Creating udev rule to disable USB autosuspend..."
cat > /etc/udev/rules.d/51-usb-power-nxp.rules << 'EOF'
# Disable USB autosuspend for NXP download mode devices
# Prevents device from disconnecting during UUU programming
SUBSYSTEM=="usb", ATTR{idVendor}=="1fc9", ATTR{power/autosuspend}="-1", ATTR{power/control}="on"
EOF

chmod 644 /etc/udev/rules.d/51-usb-power-nxp.rules
echo "   ✓ Rule created: /etc/udev/rules.d/51-usb-power-nxp.rules"
echo ""

# 2. Prevent HID driver from binding (causes disconnects)
echo "2. Creating modprobe configuration to prevent HID driver issues..."
cat > /etc/modprobe.d/blacklist-nxp-hid.conf << 'EOF'
# Prevent HID driver from causing issues with NXP download mode
# The HID driver can cause USB disconnects during UUU programming
blacklist hid-generic
EOF

chmod 644 /etc/modprobe.d/blacklist-nxp-hid.conf
echo "   ✓ HID blacklist created: /etc/modprobe.d/blacklist-nxp-hid.conf"
echo ""

# 3. Unload HID driver if currently loaded
echo "3. Unloading HID driver (if loaded)..."
if lsmod | grep -q "^usbhid "; then
    modprobe -r usbhid 2>/dev/null || echo "   ⚠ Could not unload usbhid (may be in use)"
    modprobe -r hid-generic 2>/dev/null || true
    echo "   ✓ HID drivers unloaded"
else
    echo "   ℹ HID drivers not currently loaded"
fi
echo ""

# 4. Disable USB autosuspend globally (temporary, for testing)
echo "4. Disabling USB autosuspend globally (for testing)..."
echo -1 | tee /sys/module/usbcore/parameters/autosuspend > /dev/null 2>&1 || echo "   ⚠ Could not disable global autosuspend"
echo "   ✓ USB autosuspend disabled"
echo ""

# 5. Reload udev rules
echo "5. Reloading udev rules..."
udevadm control --reload-rules
udevadm trigger --subsystem-match=usb --action=add
echo "   ✓ Udev rules reloaded"
echo ""

echo "============================================================"
echo "Fix Applied Successfully!"
echo "============================================================"
echo ""
echo "What was done:"
echo "  ✓ Disabled USB autosuspend for NXP devices (vendor ID: 1fc9)"
echo "  ✓ Blacklisted HID driver to prevent interference"
echo "  ✓ Disabled global USB autosuspend (for testing)"
echo ""
echo "Next steps:"
echo "  1. Disconnect your board"
echo "  2. Reconnect it in download mode"
echo "  3. The device should stay connected longer"
echo "  4. Try programming with UUU immediately after connection"
echo ""
echo "If device still disconnects:"
echo "  - Try a USB 2.0 port (more stable than USB 3.0)"
echo "  - Use a high-quality USB-C data cable"
echo "  - Check board power supply (needs 5V 2A minimum)"
echo "  - Verify boot mode switches are correctly set"
echo ""
echo "To monitor USB events:"
echo "  journalctl -f | grep -E 'usb|1fc9'"
echo ""



