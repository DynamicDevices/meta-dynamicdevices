#!/bin/bash
# UAC2 Module Parameter Test Script
# Tests different UAC2 module parameters to fix capture issues

show_usage() {
    echo "UAC2 Module Parameter Test Script"
    echo "Usage: $0 [test_number|stop|status]"
    echo ""
    echo "Tests:"
    echo "  1 - Fixed bInterval=1 for capture"
    echo "  2 - Fixed bInterval=2 for capture" 
    echo "  3 - Multiple sample rates (44100,48000)"
    echo "  4 - Fixed bInterval=1 + multiple rates"
    echo "  5 - Original parameters (baseline)"
    echo ""
    echo "Commands:"
    echo "  stop   - Remove UAC2 module"
    echo "  status - Show current module status"
    echo "  reload - Reload with original parameters"
}

cleanup_gadgets() {
    echo "Cleaning up USB gadgets..."
    
    # Stop any running gadget services
    systemctl stop usb-composite-gadget 2>/dev/null || true
    
    # Clean up configfs gadgets
    for gadget_dir in /sys/kernel/config/usb_gadget/g_*; do
        if [ -d "$gadget_dir" ]; then
            echo "" > "$gadget_dir/UDC" 2>/dev/null || true
        fi
    done
    
    sleep 2
}

remove_uac2_module() {
    echo "Removing UAC2 modules..."
    
    cleanup_gadgets
    
    # Remove UAC2 modules in correct order
    modprobe -r usb_f_uac2 2>/dev/null || true
    modprobe -r u_audio 2>/dev/null || true
    
    sleep 1
    
    # Verify removal
    if lsmod | grep -q usb_f_uac2; then
        echo "❌ Failed to remove usb_f_uac2 module"
        return 1
    else
        echo "✅ UAC2 modules removed"
        return 0
    fi
}

load_uac2_module() {
    local params="$1"
    echo "Loading UAC2 module with parameters: $params"
    
    # Load u_audio first (dependency)
    modprobe u_audio || return 1
    
    # Load usb_f_uac2 with parameters
    if [ -n "$params" ]; then
        modprobe usb_f_uac2 $params || return 1
    else
        modprobe usb_f_uac2 || return 1
    fi
    
    sleep 1
    
    if lsmod | grep -q usb_f_uac2; then
        echo "✅ UAC2 module loaded successfully"
        return 0
    else
        echo "❌ Failed to load UAC2 module"
        return 1
    fi
}

setup_simple_gadget() {
    echo "Setting up simple UAC2 gadget for testing..."
    
    local gadget_dir="/sys/kernel/config/usb_gadget/g_test"
    local config_dir="$gadget_dir/configs/c.1"
    local func_dir="$gadget_dir/functions/uac2.audio"
    
    # Create gadget
    mkdir -p "$gadget_dir" || return 1
    echo "0x1d6b" > "$gadget_dir/idVendor"
    echo "0x0104" > "$gadget_dir/idProduct"
    
    mkdir -p "$gadget_dir/strings/0x409"
    echo "Test UAC2 Gadget" > "$gadget_dir/strings/0x409/product"
    echo "Dynamic Devices" > "$gadget_dir/strings/0x409/manufacturer"
    echo "123456789" > "$gadget_dir/strings/0x409/serialnumber"
    
    # Create config
    mkdir -p "$config_dir/strings/0x409"
    echo "UAC2 Test Config" > "$config_dir/strings/0x409/configuration"
    echo 0x80 > "$config_dir/bmAttributes"
    echo 250 > "$config_dir/MaxPower"
    
    # Create UAC2 function
    mkdir -p "$func_dir" || return 1
    echo "Test UAC2 Audio" > "$func_dir/function_name"
    
    # Link function to config
    ln -s "$func_dir" "$config_dir/" || return 1
    
    # Enable gadget
    local udc_device="$(find /sys/class/udc -maxdepth 1 -type l | head -1 | xargs basename 2>/dev/null)"
    if [ -n "$udc_device" ]; then
        echo "$udc_device" > "$gadget_dir/UDC"
        echo "✅ Test gadget enabled on $udc_device"
        
        # Wait for enumeration
        sleep 2
        
        # Show audio devices
        echo "Available audio devices:"
        arecord -l | grep -E "(UAC|Gadget)" || echo "  No UAC2 gadget found"
        
        return 0
    else
        echo "❌ No UDC device found"
        return 1
    fi
}

test_capture() {
    echo ""
    echo "=== Testing Capture ==="
    echo "Command: arecord -D hw:UAC2Gadget,0 -c 2 -r 44100 -f S16_LE --buffer-size=1024 --period-size=256 -d 3 test.wav"
    
    if arecord -D hw:UAC2Gadget,0 -c 2 -r 44100 -f S16_LE --buffer-size=1024 --period-size=256 -d 3 test_module.wav 2>&1; then
        echo "✅ Capture test PASSED"
        ls -la test_module.wav 2>/dev/null || echo "No file created"
    else
        echo "❌ Capture test FAILED"
    fi
}

show_status() {
    echo "=== UAC2 Module Status ==="
    
    if lsmod | grep -q usb_f_uac2; then
        echo "✅ usb_f_uac2 module loaded"
        lsmod | grep uac
    else
        echo "❌ usb_f_uac2 module not loaded"
    fi
    
    echo ""
    echo "USB Gadgets:"
    ls /sys/kernel/config/usb_gadget/ 2>/dev/null || echo "  No gadgets configured"
    
    echo ""
    echo "Audio Devices:"
    arecord -l | grep -E "(UAC|Gadget)" || echo "  No UAC2 gadget found"
}

# Test configurations
case "$1" in
    "1")
        echo "=== Test 1: Fixed bInterval=1 for capture ==="
        remove_uac2_module && \
        load_uac2_module "c_hs_bint=1" && \
        setup_simple_gadget && \
        test_capture
        ;;
    "2")
        echo "=== Test 2: Fixed bInterval=2 for capture ==="
        remove_uac2_module && \
        load_uac2_module "c_hs_bint=2" && \
        setup_simple_gadget && \
        test_capture
        ;;
    "3")
        echo "=== Test 3: Multiple sample rates ==="
        remove_uac2_module && \
        load_uac2_module "c_srate=44100,48000 p_srate=44100,48000" && \
        setup_simple_gadget && \
        test_capture
        ;;
    "4")
        echo "=== Test 4: Fixed bInterval=1 + multiple rates ==="
        remove_uac2_module && \
        load_uac2_module "c_hs_bint=1 c_srate=44100,48000 p_srate=44100,48000" && \
        setup_simple_gadget && \
        test_capture
        ;;
    "5")
        echo "=== Test 5: Original parameters (baseline) ==="
        remove_uac2_module && \
        load_uac2_module "" && \
        setup_simple_gadget && \
        test_capture
        ;;
    "stop")
        cleanup_gadgets
        remove_uac2_module
        ;;
    "reload")
        echo "=== Reloading with original parameters ==="
        remove_uac2_module && load_uac2_module ""
        ;;
    "status")
        show_status
        ;;
    *)
        show_usage
        ;;
esac
