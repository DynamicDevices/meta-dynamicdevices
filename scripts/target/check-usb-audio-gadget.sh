#!/bin/bash
# Check USB audio gadget status on DT510/Sentai target board
# Run on target: ./check-usb-audio-gadget.sh
# Or via SSH: ssh fio@<TARGET_IP> 'sudo /path/to/check-usb-audio-gadget.sh'

set -e

echo "=== USB Audio Gadget Check ==="
echo ""

# 1. ConfigFS and UDC
echo "1. USB Device Controller (UDC):"
if [ -d /sys/class/udc ]; then
    ls -la /sys/class/udc/ 2>/dev/null || echo "  (empty)"
else
    echo "  /sys/class/udc not found"
fi
echo ""

# 2. ConfigFS gadgets
echo "2. ConfigFS Gadgets:"
CONFIGFS=/sys/kernel/config/usb_gadget
if [ -d "$CONFIGFS" ]; then
    for g in "$CONFIGFS"/g_*; do
        if [ -d "$g" ]; then
            name=$(basename "$g")
            udc=$(cat "$g/UDC" 2>/dev/null || echo "not bound")
            echo "  $name: UDC=$udc"
            if [ -d "$g/functions" ]; then
                for f in "$g/functions"/*; do
                    [ -d "$f" ] && echo "    - $(basename "$f")"
                done
            fi
        fi
    done
    [ -z "$(ls -A $CONFIGFS 2>/dev/null)" ] && echo "  (no gadgets configured)"
else
    echo "  $CONFIGFS not found"
fi
echo ""

# 3. Dual audio gadget status (DT510)
echo "3. DT510 Dual Audio Gadget:"
if command -v setup-usb-dual-audio-gadget &>/dev/null; then
    setup-usb-dual-audio-gadget status 2>/dev/null || echo "  (not running)"
else
    echo "  setup-usb-dual-audio-gadget not installed"
fi
echo ""

# 4. Single audio gadget status (Sentai)
echo "4. USB Composite Gadget (Sentai):"
if command -v setup-usb-composite-gadget &>/dev/null; then
    setup-usb-composite-gadget status 2>/dev/null || echo "  (not running)"
else
    echo "  setup-usb-composite-gadget not installed"
fi
echo ""

# 5. Systemd services
echo "5. USB Gadget Services:"
systemctl is-active usb-dual-audio-gadget-dt510.service 2>/dev/null && echo "  usb-dual-audio-gadget-dt510: active" || echo "  usb-dual-audio-gadget-dt510: inactive"
systemctl is-active usb-composite-gadget-fixed.service 2>/dev/null && echo "  usb-composite-gadget-fixed: active" || echo "  usb-composite-gadget-fixed: inactive"
echo ""

# 6. ALSA devices (on HOST when gadget is connected - run on host)
echo "6. ALSA devices (run on HOST with DT510 connected via USB):"
echo "  arecord -l  # capture devices"
echo "  aplay -l    # playback devices"
echo ""

# 7. Kernel modules
echo "7. USB Audio Gadget Kernel Modules:"
lsmod 2>/dev/null | grep -E "uac|u_audio|usb_f_" || echo "  (none loaded)"
echo ""

echo "=== To enable DT510 dual audio: ==="
echo "  sudo systemctl start usb-dual-audio-gadget-dt510.service"
echo "  # Or manually: sudo setup-usb-dual-audio-gadget setup"
echo ""
echo "=== To enable Sentai single audio: ==="
echo "  sudo systemctl start usb-composite-gadget-fixed.service"
echo "  # Or manually: sudo setup-usb-composite-gadget setup"
