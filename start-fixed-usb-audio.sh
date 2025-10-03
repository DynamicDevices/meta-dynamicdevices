#!/bin/bash
# Start USB Composite Gadget with Fixed UAC2 Capture
# This script properly handles module reloading with the c_hs_bint=1 parameter

echo "=== Starting USB Composite Gadget with Fixed UAC2 Capture ==="

# Stop existing service and clean up
echo "1. Stopping existing USB gadget service..."
systemctl stop usb-composite-gadget 2>/dev/null || true

# Clean up all USB gadgets
echo "2. Cleaning up USB gadgets..."
for gadget_dir in /sys/kernel/config/usb_gadget/g_*; do
    if [ -d "$gadget_dir" ]; then
        echo "" > "$gadget_dir/UDC" 2>/dev/null || true
        rm -f "$gadget_dir/configs/c.1"/* 2>/dev/null || true
    fi
done

sleep 2

# Remove and reload UAC2 modules with fixed parameters
echo "3. Reloading UAC2 module with c_hs_bint=1..."
modprobe -r usb_f_uac2 2>/dev/null || true
modprobe -r u_audio 2>/dev/null || true
sleep 1

modprobe u_audio
modprobe usb_f_uac2 c_hs_bint=1

if lsmod | grep -q usb_f_uac2; then
    echo "✅ UAC2 module loaded with fixed parameters"
else
    echo "❌ Failed to load UAC2 module"
    exit 1
fi

# Start the USB composite gadget service
echo "4. Starting USB composite gadget service..."
systemctl start usb-composite-gadget

sleep 3

# Check status
echo "5. Checking service status..."
if systemctl is-active --quiet usb-composite-gadget; then
    echo "✅ USB Composite Gadget service is running"
    
    # Show available audio devices
    echo ""
    echo "Available audio devices:"
    arecord -l | grep -E "(UAC|Gadget)" || echo "  No UAC2 gadget found"
    
    echo ""
    echo "🎵 Test commands:"
    echo "  Playback: speaker-test -D hw:UAC2Gadget,0 -c 2 -r 48000 -f S16_LE -t sine -l 3"
    echo "  Capture:  arecord -D hw:UAC2Gadget,0 -c 2 -r 44100 -f S16_LE --buffer-size=1024 --period-size=256 -d 5 test.wav"
    
else
    echo "❌ USB Composite Gadget service failed to start"
    systemctl status usb-composite-gadget --no-pager -l
    exit 1
fi

echo ""
echo "✅ USB Composite Gadget with Fixed UAC2 Capture is ready!"
