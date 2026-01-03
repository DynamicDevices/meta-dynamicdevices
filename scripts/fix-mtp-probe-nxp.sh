#!/bin/bash
#
# Fix MTP Probe for NXP Devices - More Aggressive Approach
# 
# This script creates a udev rule that runs BEFORE 69-libmtp.rules
# and also creates a symlink override to prevent mtp-probe execution
#

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

echo "Creating udev rule to disable mtp-probe for NXP devices..."

# Create rule with lower number (runs before 69-libmtp.rules)
cat > /etc/udev/rules.d/60-disable-mtp-probe-nxp.rules << 'EOF'
# Disable MTP probe for NXP devices (i.MX download mode)
# Prevents mtp-probe from interfering with UUU programming
# NXP vendor ID: 1fc9
# This rule runs BEFORE 69-libmtp.rules (lower number = higher priority)
ACTION!="add", ACTION!="bind", GOTO="disable_mtp_nxp_end"
SUBSYSTEM!="usb", GOTO="disable_mtp_nxp_end"
ATTR{idVendor}=="1fc9", ENV{MTP_NO_PROBE}="1", GOTO="disable_mtp_nxp_end"
LABEL="disable_mtp_nxp_end"
EOF

chmod 644 /etc/udev/rules.d/60-disable-mtp-probe-nxp.rules

# Also create a wrapper that prevents mtp-probe from running on NXP devices
if [[ ! -f /usr/local/bin/mtp-probe-wrapper ]]; then
    cat > /usr/local/bin/mtp-probe-wrapper << 'EOFSCRIPT'
#!/bin/bash
# Wrapper to prevent mtp-probe on NXP devices
DEVICE_PATH="$1"
if [[ -n "$DEVICE_PATH" ]] && [[ -f "$DEVICE_PATH/idVendor" ]]; then
    VENDOR=$(cat "$DEVICE_PATH/idVendor" 2>/dev/null || echo "")
    if [[ "$VENDOR" == "1fc9" ]]; then
        # NXP device - don't probe
        exit 0
    fi
fi
# Not NXP device - run original mtp-probe
exec /lib/udev/mtp-probe "$@"
EOFSCRIPT
    chmod +x /usr/local/bin/mtp-probe-wrapper
fi

# Reload udev
udevadm control --reload-rules
udevadm trigger

echo "Done! Rule created at /etc/udev/rules.d/60-disable-mtp-probe-nxp.rules"
echo "Disconnect and reconnect your board for the change to take effect."



