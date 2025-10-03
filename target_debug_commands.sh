#!/bin/bash
# Complete USB Audio Gadget Debug and UAC1 Setup Script
# Copy and paste these commands on the target board (192.168.0.203)

echo "=== USB Audio Gadget Debug and UAC1 Setup ==="
echo "Run these commands on the target board step by step"
echo ""

echo "STEP 1: Find existing USB gadget setup"
echo "======================================"
echo "find /home/fio -name \"*usb*gadget*\" -type f 2>/dev/null"
echo "find /usr/local -name \"*usb*gadget*\" -type f 2>/dev/null"
echo "find /opt -name \"*usb*gadget*\" -type f 2>/dev/null"
echo "systemctl status usb-composite-gadget 2>/dev/null || echo \"No systemd service found\""
echo "ls -la /sys/kernel/config/usb_gadget/"
echo ""

echo "STEP 2: Check kernel logs for USB audio issues"
echo "=============================================="
echo "dmesg | grep -i \"uac\\|usb.*audio\\|gadget\" | tail -10"
echo ""

echo "STEP 3: Manual cleanup of existing gadgets"
echo "=========================================="
echo "echo \"Cleaning up existing USB gadgets...\""
echo "for gadget_dir in /sys/kernel/config/usb_gadget/g_*; do"
echo "    if [ -d \"\$gadget_dir\" ]; then"
echo "        gadget_name=\$(basename \"\$gadget_dir\")"
echo "        echo \"Disabling \$gadget_name...\""
echo "        sudo sh -c \"echo '' > \$gadget_dir/UDC\" 2>/dev/null || true"
echo "    fi"
echo "done"
echo "sleep 2"
echo "ls -la /sys/kernel/config/usb_gadget/"
echo ""

echo "STEP 4: Create UAC1 Mixed Audio Gadget Script"
echo "============================================="
echo "cat > /home/fio/setup-usb-mixed-audio-gadget << 'EOF'"
cat << 'SCRIPT_EOF'
#!/bin/sh
# USB Mixed Audio Gadget Setup Script - UAC1 Version
CONFIGFS=/sys/kernel/config/usb_gadget
GADGET_NAME="g_mixed_audio"
GADGET=$CONFIGFS/$GADGET_NAME
CONFIG=$GADGET/configs/c.1
FUNCTIONS=$GADGET/functions

# USB Device Descriptor
VID="0x1d6b"
PID="0x0104"
SERIALNUMBER="$(cat /sys/devices/soc0/serial_number 2>/dev/null || cat /etc/machine-id 2>/dev/null || echo 'DD-UNKNOWN')"
MANUFACTURER="Dynamic Devices Ltd"
PRODUCT="Jaguar Sentai Mixed Audio Device"

# Audio Configuration
SAMPLE_RATE=48000
SAMPLE_SIZE=2
CHANNELS=2

add_acm_function() {
    function_name="$1"
    mkdir "$FUNCTIONS/acm.$function_name" || echo "  Couldn't create $FUNCTIONS/acm.$function_name"
    ln -s "$FUNCTIONS/acm.$function_name" "$CONFIG" || echo "  Couldn't symlink acm.$function_name"
}

add_uac1_function() {
    function_name="$1"
    mkdir "$FUNCTIONS/uac1.$function_name" || echo "  Couldn't create $FUNCTIONS/uac1.$function_name"
    echo "$PRODUCT UAC1" > "$FUNCTIONS/uac1.$function_name/function_name"
    echo $SAMPLE_RATE > "$FUNCTIONS/uac1.$function_name/c_srate"
    echo $SAMPLE_RATE > "$FUNCTIONS/uac1.$function_name/p_srate"
    echo $SAMPLE_SIZE > "$FUNCTIONS/uac1.$function_name/c_ssize"
    echo $SAMPLE_SIZE > "$FUNCTIONS/uac1.$function_name/p_ssize"
    echo $CHANNELS > "$FUNCTIONS/uac1.$function_name/c_chmask"
    echo $CHANNELS > "$FUNCTIONS/uac1.$function_name/p_chmask"
    ln -s "$FUNCTIONS/uac1.$function_name" "$CONFIG" || echo "  Couldn't symlink uac1.$function_name"
}

setup_gadget() {
    echo "Setting up UAC1 Mixed Audio Gadget..."
    mkdir "$GADGET" || echo "  Couldn't create $GADGET"
    echo $VID > "$GADGET/idVendor"
    echo $PID > "$GADGET/idProduct"
    mkdir "$GADGET/strings/0x409" || echo "  Couldn't create strings"
    echo "$SERIALNUMBER" > "$GADGET/strings/0x409/serialnumber"
    echo "$MANUFACTURER" > "$GADGET/strings/0x409/manufacturer"
    echo "$PRODUCT" > "$GADGET/strings/0x409/product"
    mkdir "$CONFIG" || echo "  Couldn't create config"
    mkdir "$CONFIG/strings/0x409" || echo "  Couldn't create config strings"
    echo "USB Mixed Audio Device" > "$CONFIG/strings/0x409/configuration"
    echo 0x80 > "$CONFIG/bmAttributes"
    echo 250 > "$CONFIG/MaxPower"
    add_acm_function "debug"
    add_uac1_function "audio"
    echo "UAC1 Mixed Audio Gadget configured!"
}

enable_gadget() {
    udc_device="$(find /sys/class/udc -maxdepth 1 -type l | head -1 | xargs basename 2>/dev/null)"
    echo "Enabling on $udc_device..."
    echo "$udc_device" > "$GADGET/UDC" || echo "  Couldn't write UDC"
    echo "UAC1 Mixed Audio Gadget enabled!"
}

disable_gadget() {
    if [ -d "$GADGET" ]; then
        echo "" > "$GADGET/UDC" 2>/dev/null || true
        rm -f "$CONFIG"/acm.* 2>/dev/null || true
        rm -f "$CONFIG"/uac1.* 2>/dev/null || true
        rm -rf "$CONFIG" 2>/dev/null || true
        rm -rf "${FUNCTIONS:?}"/* 2>/dev/null || true
        rm -rf "$GADGET" 2>/dev/null || true
        echo "UAC1 Mixed Audio Gadget disabled!"
    fi
}

cleanup_existing() {
    for gadget_dir in "$CONFIGFS"/g_*; do
        if [ -d "$gadget_dir" ]; then
            echo "" > "$gadget_dir/UDC" 2>/dev/null || true
        fi
    done
    sleep 1
}

case "$1" in
    "setup"|"start")
        cleanup_existing
        disable_gadget
        setup_gadget
        enable_gadget
        ;;
    "stop"|"disable")
        disable_gadget
        ;;
    "status")
        if [ -d "$GADGET" ]; then
            echo "UAC1 Gadget: CONFIGURED"
            echo "UDC: $(cat "$GADGET/UDC" 2>/dev/null || echo 'Not bound')"
        else
            echo "UAC1 Gadget: NOT CONFIGURED"
        fi
        ;;
    *)
        echo "Usage: $0 {setup|stop|status}"
        exit 1
        ;;
esac
SCRIPT_EOF
echo "EOF"
echo ""

echo "STEP 5: Make script executable and test"
echo "======================================="
echo "chmod +x /home/fio/setup-usb-mixed-audio-gadget"
echo ""

echo "STEP 6: Setup UAC1 gadget"
echo "========================="
echo "sudo /home/fio/setup-usb-mixed-audio-gadget setup"
echo ""

echo "STEP 7: Check audio devices"
echo "==========================="
echo "arecord -l"
echo ""

echo "STEP 8: Test UAC1 capture"
echo "========================="
echo "arecord -D hw:UAC1Gadget,0 -c 2 -r 48000 -f S16_LE -d 5 test_uac1.wav"
echo ""

echo "STEP 9: Alternative tests if UAC1Gadget not found"
echo "================================================="
echo "# Try different device names:"
echo "arecord -D hw:0,0 -c 2 -r 48000 -f S16_LE -d 5 test_card0.wav"
echo "arecord -D hw:1,0 -c 2 -r 48000 -f S16_LE -d 5 test_card1.wav"
echo "arecord -D hw:2,0 -c 2 -r 48000 -f S16_LE -d 5 test_card2.wav"
echo "arecord -D hw:3,0 -c 2 -r 48000 -f S16_LE -d 5 test_card3.wav"
echo ""

echo "STEP 10: Check gadget status"
echo "============================"
echo "sudo /home/fio/setup-usb-mixed-audio-gadget status"
echo "ls -la /sys/kernel/config/usb_gadget/"
echo ""

echo "=== END OF SCRIPT ==="
echo "Copy and paste each step above on the target board"
