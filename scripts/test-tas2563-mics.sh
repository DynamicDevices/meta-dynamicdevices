#!/bin/bash

#
# Test script for TAS2563 integrated microphone functionality
# 
# Usage: ./test-tas2563-mics.sh [test_type]
# test_type: quick, full, debug
#

TEST_TYPE=${1:-quick}

echo "========================================"
echo "TAS2563 Microphone Test Script"
echo "========================================"
echo "Test type: $TEST_TYPE"
echo ""

# Function to check if audio cards are detected
check_audio_cards() {
    echo "=== Audio Cards Detection ==="
    cat /proc/asound/cards
    echo ""
    
    if ! grep -q "tas2563audio" /proc/asound/cards; then
        echo "❌ ERROR: tas2563audio card not found!"
        return 1
    else
        echo "✅ TAS2563 audio card detected"
    fi
    
    return 0
}

# Function to check TAS2563 module
check_tas2563_module() {
    echo "=== TAS2563 Module Status ==="
    if lsmod | grep -q tas256; then
        echo "✅ TAS driver loaded:"
        lsmod | grep tas256
    else
        echo "❌ No TAS driver found in lsmod"
    fi
    echo ""
}

# Function to show ALSA controls
show_alsa_controls() {
    echo "=== ALSA Controls for TAS2563 ==="
    amixer -c tas2563audio controls 2>/dev/null || echo "❌ Cannot access TAS2563 controls"
    echo ""
}

# Function to test microphone capture
test_microphone_capture() {
    echo "=== Testing Microphone Capture ==="
    
    # Test basic capture capability
    echo "Testing 2-second capture from TAS2563..."
    if arecord -D hw:tas2563audio,0,1 -f S16_LE -r 16000 -c 2 -d 2 /tmp/tas2563_mic_test.wav 2>/dev/null; then
        echo "✅ Microphone capture successful"
        
        # Check file size to verify actual data was captured
        FILE_SIZE=$(stat -c%s /tmp/tas2563_mic_test.wav 2>/dev/null || echo 0)
        if [ "$FILE_SIZE" -gt 1000 ]; then
            echo "✅ Audio data captured (${FILE_SIZE} bytes)"
        else
            echo "⚠️  WARNING: Capture file too small (${FILE_SIZE} bytes)"
        fi
        
        rm -f /tmp/tas2563_mic_test.wav
    else
        echo "❌ Microphone capture failed"
        echo "Trying alternative capture methods..."
        
        # Try with different parameters
        arecord -D hw:tas2563audio,0 -f S16_LE -r 16000 -c 1 -d 1 /tmp/tas2563_alt_test.wav 2>/dev/null && {
            echo "✅ Alternative capture method worked"
            rm -f /tmp/tas2563_alt_test.wav
        } || echo "❌ All capture methods failed"
    fi
    echo ""
}

# Function to test speaker playback
test_speaker_playback() {
    echo "=== Testing Speaker Playback ==="
    
    # Generate a test tone
    echo "Generating test tone and playing through TAS2563..."
    
    # Create a short test tone (440Hz for 1 second)
    if command -v speaker-test >/dev/null 2>&1; then
        timeout 3 speaker-test -D hw:tas2563audio,0 -t sine -f 440 -l 1 >/dev/null 2>&1 && {
            echo "✅ Speaker test tone played successfully"
        } || echo "⚠️  Speaker test had issues (this may be normal)"
    else
        echo "⚠️  speaker-test not available, skipping playback test"
    fi
    echo ""
}

# Function to show device tree configuration
show_device_tree_info() {
    echo "=== Device Tree Configuration ==="
    
    # Check TAS2563 device tree node
    if [ -d "/proc/device-tree/soc@0/bus@30800000/i2c@30a30000/tas2563@4c" ]; then
        echo "✅ TAS2563 device tree node found"
        
        echo "TAS2563 properties:"
        ls /proc/device-tree/soc@0/bus@30800000/i2c@30a30000/tas2563@4c/ 2>/dev/null | head -10
        
        # Check if reset GPIO is configured
        if [ -f "/proc/device-tree/soc@0/bus@30800000/i2c@30a30000/tas2563@4c/ti,reset-gpio" ]; then
            echo "✅ Reset GPIO configured"
        else
            echo "⚠️  Reset GPIO not configured"
        fi
        
    else
        echo "❌ TAS2563 device tree node not found"
    fi
    echo ""
}

# Function to run debug information
show_debug_info() {
    echo "=== Debug Information ==="
    
    echo "Kernel version:"
    uname -r
    echo ""
    
    echo "Recent kernel messages related to TAS2563:"
    dmesg | grep -i tas | tail -5 2>/dev/null || echo "No TAS-related kernel messages (or insufficient permissions)"
    echo ""
    
    echo "SAI3 status:"
    if [ -d "/proc/device-tree/soc@0/bus@30000000/spba-bus@30000000/sai@30020000" ]; then
        echo "✅ SAI3 device tree node exists"
        cat /proc/device-tree/soc@0/bus@30000000/spba-bus@30000000/sai@30020000/status 2>/dev/null || echo "Status unknown"
    else
        echo "❌ SAI3 device tree node not found"
    fi
    echo ""
}

# Main test execution
echo "Starting TAS2563 microphone tests..."
echo ""

check_audio_cards || exit 1
check_tas2563_module

case "$TEST_TYPE" in
    "quick")
        show_alsa_controls
        test_microphone_capture
        ;;
    "full")
        show_alsa_controls
        test_microphone_capture
        test_speaker_playback
        show_device_tree_info
        ;;
    "debug")
        show_alsa_controls
        test_microphone_capture
        test_speaker_playback
        show_device_tree_info
        show_debug_info
        ;;
    *)
        echo "Unknown test type: $TEST_TYPE"
        echo "Available types: quick, full, debug"
        exit 1
        ;;
esac

echo "========================================"
echo "TAS2563 microphone test completed"
echo "========================================"
