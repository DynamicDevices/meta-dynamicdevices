#!/bin/bash
# Setup UAC2 Gadget with Fixed Capture Parameters
# This script creates a UAC2 gadget with c_hs_bint=1 for working capture

CONFIGFS=/sys/kernel/config/usb_gadget
GADGET_NAME="g_fixed_uac2"
GADGET=$CONFIGFS/$GADGET_NAME
CONFIG=$GADGET/configs/c.1
FUNCTIONS=$GADGET/functions

# USB Device Descriptor
VID="0x1d6b"  # Linux Foundation
PID="0x0104"  # Multifunction Composite Gadget
MANUFACTURER="Dynamic Devices Ltd"
PRODUCT="Jaguar Sentai Fixed UAC2"

cleanup() {
    echo "Cleaning up existing gadgets..."
    for gadget_dir in "$CONFIGFS"/g_*; do
        if [ -d "$gadget_dir" ]; then
            echo "" > "$gadget_dir/UDC" 2>/dev/null || true
            rm -f "$gadget_dir/configs/c.1"/* 2>/dev/null || true
            rm -rf "$gadget_dir" 2>/dev/null || true
        fi
    done
    sleep 1
}

setup_gadget() {
    echo "=== Setting up UAC2 Gadget with Fixed Capture Parameters ==="
    
    # Create gadget
    mkdir -p "$GADGET" || return 1
    echo $VID > "$GADGET/idVendor"
    echo $PID > "$GADGET/idProduct"
    
    mkdir -p "$GADGET/strings/0x409"
    echo "$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo '0123456789')" > "$GADGET/strings/0x409/serialnumber"
    echo "$MANUFACTURER" > "$GADGET/strings/0x409/manufacturer"
    echo "$PRODUCT" > "$GADGET/strings/0x409/product"
    
    # Create config
    mkdir -p "$CONFIG/strings/0x409"
    echo "Fixed UAC2 Configuration" > "$CONFIG/strings/0x409/configuration"
    echo 0x80 > "$CONFIG/bmAttributes"  # Bus-powered
    echo 250 > "$CONFIG/MaxPower"       # 500mA
    
    # Create UAC2 function
    mkdir -p "$FUNCTIONS/uac2.audio" || return 1
    echo "$PRODUCT Audio" > "$FUNCTIONS/uac2.audio/function_name"
    
    # Set audio parameters
    echo 48000 > "$FUNCTIONS/uac2.audio/c_srate"
    echo 48000 > "$FUNCTIONS/uac2.audio/p_srate"
    echo 2 > "$FUNCTIONS/uac2.audio/c_ssize"
    echo 2 > "$FUNCTIONS/uac2.audio/p_ssize"
    echo "async" > "$FUNCTIONS/uac2.audio/c_sync"
    echo 3 > "$FUNCTIONS/uac2.audio/c_chmask"  # Stereo
    echo 3 > "$FUNCTIONS/uac2.audio/p_chmask"  # Stereo
    
    # THE KEY FIX: Set c_hs_bint to 1 for fixed timing
    echo 1 > "$FUNCTIONS/uac2.audio/c_hs_bint"
    echo 1 > "$FUNCTIONS/uac2.audio/p_hs_bint"
    
    echo "✅ UAC2 function configured with c_hs_bint=1"
    
    # Link function to config
    ln -s "$FUNCTIONS/uac2.audio" "$CONFIG/" || return 1
    
    # Enable gadget
    local udc_device="$(find /sys/class/udc -maxdepth 1 -type l | head -1 | xargs basename 2>/dev/null)"
    if [ -n "$udc_device" ]; then
        echo "$udc_device" > "$GADGET/UDC"
        echo "✅ Fixed UAC2 gadget enabled on $udc_device"
        
        # Wait for enumeration
        sleep 2
        
        # Show audio devices
        echo ""
        echo "Available audio devices:"
        arecord -l | grep -E "(UAC|Gadget)" || echo "  No UAC2 gadget found"
        
        echo ""
        echo "🎵 Test commands:"
        echo "  Playback: speaker-test -D hw:UAC2Gadget,0 -c 2 -r 48000 -f S16_LE -t sine -l 3"
        echo "  Capture:  arecord -D hw:UAC2Gadget,0 -c 2 -r 44100 -f S16_LE --buffer-size=1024 --period-size=256 -d 5 test.wav"
        
        return 0
    else
        echo "❌ No UDC device found"
        return 1
    fi
}

show_status() {
    echo "=== Fixed UAC2 Gadget Status ==="
    
    if [ -d "$GADGET" ]; then
        echo "✅ Gadget configured"
        echo "UDC: $(cat "$GADGET/UDC" 2>/dev/null || echo 'Not bound')"
        
        if [ -d "$FUNCTIONS/uac2.audio" ]; then
            echo ""
            echo "Audio Function Parameters:"
            echo "  c_hs_bint: $(cat "$FUNCTIONS/uac2.audio/c_hs_bint" 2>/dev/null || echo 'N/A')"
            echo "  p_hs_bint: $(cat "$FUNCTIONS/uac2.audio/p_hs_bint" 2>/dev/null || echo 'N/A')"
            echo "  c_sync: $(cat "$FUNCTIONS/uac2.audio/c_sync" 2>/dev/null || echo 'N/A')"
            echo "  Sample Rate: $(cat "$FUNCTIONS/uac2.audio/p_srate" 2>/dev/null || echo 'N/A') Hz"
        fi
    else
        echo "❌ Gadget not configured"
    fi
    
    echo ""
    echo "Audio Devices:"
    arecord -l | grep -E "(UAC|Gadget)" || echo "  No UAC2 gadget found"
}

case "$1" in
    "setup"|"start")
        cleanup
        setup_gadget
        ;;
    "stop")
        cleanup
        echo "✅ Fixed UAC2 gadget stopped"
        ;;
    "status")
        show_status
        ;;
    *)
        echo "Usage: $0 {setup|start|stop|status}"
        echo ""
        echo "This script creates a UAC2 gadget with c_hs_bint=1 to fix capture issues."
        exit 1
        ;;
esac
