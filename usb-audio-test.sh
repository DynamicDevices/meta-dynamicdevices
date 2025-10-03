#!/bin/bash
# Simple USB Audio Gadget Test Script
# Usage: ./usb-audio-test.sh [config_number]

CONFIGFS=/sys/kernel/config/usb_gadget
GADGET_NAME="g_audio_test"
GADGET=$CONFIGFS/$GADGET_NAME
CONFIG=$GADGET/configs/c.1
FUNCTIONS=$GADGET/functions

# USB Device Descriptor
VID="0x1d6b"  # Linux Foundation
PID="0x0104"  # Multifunction Composite Gadget
MANUFACTURER="Dynamic Devices Ltd"
PRODUCT="Jaguar Sentai Audio Test"

cleanup() {
    echo "Cleaning up existing gadgets..."
    for gadget_dir in "$CONFIGFS"/g_*; do
        if [ -d "$gadget_dir" ]; then
            echo "" > "$gadget_dir/UDC" 2>/dev/null || true
        fi
    done
    
    if [ -d "$GADGET" ]; then
        echo "" > "$GADGET/UDC" 2>/dev/null || true
        rm -f "$CONFIG"/* 2>/dev/null || true
        rm -rf "$CONFIG" 2>/dev/null || true
        rm -rf "$FUNCTIONS"/* 2>/dev/null || true
        rm -rf "$GADGET/strings" 2>/dev/null || true
        rm -rf "$GADGET" 2>/dev/null || true
    fi
    sleep 1
}

setup_base() {
    mkdir -p "$GADGET" || return 1
    echo $VID > "$GADGET/idVendor"
    echo $PID > "$GADGET/idProduct"
    
    mkdir -p "$GADGET/strings/0x409"
    echo "$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo '0123456789')" > "$GADGET/strings/0x409/serialnumber"
    echo "$MANUFACTURER" > "$GADGET/strings/0x409/manufacturer"
    echo "$PRODUCT" > "$GADGET/strings/0x409/product"
    
    mkdir -p "$CONFIG/strings/0x409"
    echo "Audio Test Configuration" > "$CONFIG/strings/0x409/configuration"
    echo 0x80 > "$CONFIG/bmAttributes"  # Bus-powered
    echo 250 > "$CONFIG/MaxPower"       # 500mA
}

enable_gadget() {
    udc_device="$(find /sys/class/udc -maxdepth 1 -type l | head -1 | xargs basename 2>/dev/null)"
    if [ -n "$udc_device" ]; then
        echo "Enabling gadget on $udc_device..."
        echo "$udc_device" > "$GADGET/UDC"
        echo "✅ USB Audio Gadget enabled!"
        echo "Check with: arecord -l && aplay -l"
    else
        echo "❌ No UDC device found"
        return 1
    fi
}

# Configuration 1: Standard UAC2 (48kHz, Stereo, Async)
config1() {
    echo "=== Config 1: Standard UAC2 (48kHz, Stereo, Async) ==="
    
    mkdir "$FUNCTIONS/uac2.audio"
    echo "$PRODUCT Standard" > "$FUNCTIONS/uac2.audio/function_name"
    echo 48000 > "$FUNCTIONS/uac2.audio/c_srate"
    echo 48000 > "$FUNCTIONS/uac2.audio/p_srate"
    echo 2 > "$FUNCTIONS/uac2.audio/c_ssize"
    echo 2 > "$FUNCTIONS/uac2.audio/p_ssize"
    echo "async" > "$FUNCTIONS/uac2.audio/c_sync"
    echo 3 > "$FUNCTIONS/uac2.audio/c_chmask"  # Stereo
    echo 3 > "$FUNCTIONS/uac2.audio/p_chmask"  # Stereo
    
    ln -s "$FUNCTIONS/uac2.audio" "$CONFIG"
}

# Configuration 2: UAC2 with Adaptive Sync
config2() {
    echo "=== Config 2: UAC2 with Adaptive Sync ==="
    
    mkdir "$FUNCTIONS/uac2.audio"
    echo "$PRODUCT Adaptive" > "$FUNCTIONS/uac2.audio/function_name"
    echo 48000 > "$FUNCTIONS/uac2.audio/c_srate"
    echo 48000 > "$FUNCTIONS/uac2.audio/p_srate"
    echo 2 > "$FUNCTIONS/uac2.audio/c_ssize"
    echo 2 > "$FUNCTIONS/uac2.audio/p_ssize"
    echo "adaptive" > "$FUNCTIONS/uac2.audio/c_sync"
    echo 3 > "$FUNCTIONS/uac2.audio/c_chmask"
    echo 3 > "$FUNCTIONS/uac2.audio/p_chmask"
    
    ln -s "$FUNCTIONS/uac2.audio" "$CONFIG"
}

# Configuration 3: UAC2 Mono (single channel)
config3() {
    echo "=== Config 3: UAC2 Mono (Single Channel) ==="
    
    mkdir "$FUNCTIONS/uac2.audio"
    echo "$PRODUCT Mono" > "$FUNCTIONS/uac2.audio/function_name"
    echo 48000 > "$FUNCTIONS/uac2.audio/c_srate"
    echo 48000 > "$FUNCTIONS/uac2.audio/p_srate"
    echo 2 > "$FUNCTIONS/uac2.audio/c_ssize"
    echo 2 > "$FUNCTIONS/uac2.audio/p_ssize"
    echo "async" > "$FUNCTIONS/uac2.audio/c_sync"
    echo 1 > "$FUNCTIONS/uac2.audio/c_chmask"  # Mono
    echo 1 > "$FUNCTIONS/uac2.audio/p_chmask"  # Mono
    
    ln -s "$FUNCTIONS/uac2.audio" "$CONFIG"
}

# Configuration 4: UAC2 44.1kHz (sometimes more compatible)
config4() {
    echo "=== Config 4: UAC2 44.1kHz ==="
    
    mkdir "$FUNCTIONS/uac2.audio"
    echo "$PRODUCT 44k1" > "$FUNCTIONS/uac2.audio/function_name"
    echo 44100 > "$FUNCTIONS/uac2.audio/c_srate"
    echo 44100 > "$FUNCTIONS/uac2.audio/p_srate"
    echo 2 > "$FUNCTIONS/uac2.audio/c_ssize"
    echo 2 > "$FUNCTIONS/uac2.audio/p_ssize"
    echo "async" > "$FUNCTIONS/uac2.audio/c_sync"
    echo 3 > "$FUNCTIONS/uac2.audio/c_chmask"
    echo 3 > "$FUNCTIONS/uac2.audio/p_chmask"
    
    ln -s "$FUNCTIONS/uac2.audio" "$CONFIG"
}

# Configuration 5: Playback-only UAC2
config5() {
    echo "=== Config 5: Playback-Only UAC2 ==="
    
    mkdir "$FUNCTIONS/uac2.audio"
    echo "$PRODUCT PlayOnly" > "$FUNCTIONS/uac2.audio/function_name"
    echo 48000 > "$FUNCTIONS/uac2.audio/c_srate"
    echo 48000 > "$FUNCTIONS/uac2.audio/p_srate"
    echo 2 > "$FUNCTIONS/uac2.audio/c_ssize"
    echo 2 > "$FUNCTIONS/uac2.audio/p_ssize"
    echo "async" > "$FUNCTIONS/uac2.audio/c_sync"
    echo 0 > "$FUNCTIONS/uac2.audio/c_chmask"  # No capture
    echo 3 > "$FUNCTIONS/uac2.audio/p_chmask"  # Stereo playback
    
    ln -s "$FUNCTIONS/uac2.audio" "$CONFIG"
}

# Configuration 6: Capture-only UAC2
config6() {
    echo "=== Config 6: Capture-Only UAC2 ==="
    
    mkdir "$FUNCTIONS/uac2.audio"
    echo "$PRODUCT CapOnly" > "$FUNCTIONS/uac2.audio/function_name"
    echo 48000 > "$FUNCTIONS/uac2.audio/c_srate"
    echo 48000 > "$FUNCTIONS/uac2.audio/p_srate"
    echo 2 > "$FUNCTIONS/uac2.audio/c_ssize"
    echo 2 > "$FUNCTIONS/uac2.audio/p_ssize"
    echo "async" > "$FUNCTIONS/uac2.audio/c_sync"
    echo 3 > "$FUNCTIONS/uac2.audio/c_chmask"  # Stereo capture
    echo 0 > "$FUNCTIONS/uac2.audio/p_chmask"  # No playback
    
    ln -s "$FUNCTIONS/uac2.audio" "$CONFIG"
}

show_usage() {
    echo "USB Audio Gadget Test Script"
    echo "Usage: $0 [config_number|stop|status]"
    echo ""
    echo "Configurations:"
    echo "  1 - Standard UAC2 (48kHz, Stereo, Async)"
    echo "  2 - UAC2 with Adaptive Sync"
    echo "  3 - UAC2 Mono (Single Channel)"
    echo "  4 - UAC2 44.1kHz"
    echo "  5 - Playback-Only UAC2"
    echo "  6 - Capture-Only UAC2"
    echo ""
    echo "Commands:"
    echo "  stop   - Disable gadget"
    echo "  status - Show current status"
    echo ""
    echo "Test commands after setup:"
    echo "  Playback: speaker-test -D hw:UAC2Gadget,0 -c 2 -r 48000 -f S16_LE -t sine"
    echo "  Capture:  arecord -D hw:UAC2Gadget,0 -c 2 -r 44100 -f S16_LE --buffer-size=1024 --period-size=256 -d 5 test.wav"
}

show_status() {
    echo "=== USB Audio Gadget Status ==="
    if [ -d "$GADGET" ]; then
        echo "Gadget: CONFIGURED"
        echo "UDC: $(cat "$GADGET/UDC" 2>/dev/null || echo 'Not bound')"
        echo "Product: $(cat "$GADGET/strings/0x409/product" 2>/dev/null || echo 'N/A')"
        
        if [ -d "$FUNCTIONS/uac2.audio" ]; then
            echo ""
            echo "Audio Function:"
            echo "  Sample Rate: $(cat "$FUNCTIONS/uac2.audio/p_srate" 2>/dev/null || echo 'N/A') Hz"
            echo "  Capture Channels: $(cat "$FUNCTIONS/uac2.audio/c_chmask" 2>/dev/null || echo 'N/A')"
            echo "  Playback Channels: $(cat "$FUNCTIONS/uac2.audio/p_chmask" 2>/dev/null || echo 'N/A')"
            echo "  Sync Mode: $(cat "$FUNCTIONS/uac2.audio/c_sync" 2>/dev/null || echo 'N/A')"
        fi
    else
        echo "Gadget: NOT CONFIGURED"
    fi
    
    echo ""
    echo "Available Audio Devices:"
    arecord -l 2>/dev/null | grep -E "(UAC|Gadget)" || echo "  No USB audio gadget found"
}

# Main script
case "$1" in
    "1") cleanup && setup_base && config1 && enable_gadget ;;
    "2") cleanup && setup_base && config2 && enable_gadget ;;
    "3") cleanup && setup_base && config3 && enable_gadget ;;
    "4") cleanup && setup_base && config4 && enable_gadget ;;
    "5") cleanup && setup_base && config5 && enable_gadget ;;
    "6") cleanup && setup_base && config6 && enable_gadget ;;
    "stop") cleanup && echo "✅ USB Audio Gadget stopped" ;;
    "status") show_status ;;
    *) show_usage ;;
esac
