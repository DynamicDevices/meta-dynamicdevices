#!/bin/bash
# RTC Testing Script for imx93-jaguar-eink Build 2032

echo "🔍 Testing PCF2131 RTC Functionality on imx93-jaguar-eink"
echo "============================================================"

# Test 1: Check if RTC device is detected
echo "1. Checking RTC device detection..."
if [ -e /dev/rtc0 ]; then
    echo "   ✅ /dev/rtc0 exists"
    ls -la /dev/rtc*
else
    echo "   ❌ /dev/rtc0 not found"
fi

# Test 2: Check RTC driver in kernel
echo "2. Checking RTC driver..."
dmesg | grep -i "rtc\|pcf" | tail -5

# Test 3: Check I2C3 interface
echo "3. Checking I2C3 interface..."
if [ -e /dev/i2c-3 ]; then
    echo "   ✅ I2C3 interface available"
    # Try to detect PCF2131 at address 0x53
    i2cdetect -y 3 2>/dev/null | grep -E "50|53" || echo "   ⚠️  Device scan (may need root)"
else
    echo "   ❌ I2C3 interface not found"
fi

# Test 4: Test RTC read/write functionality
echo "4. Testing RTC functionality..."
if command -v hwclock >/dev/null 2>&1; then
    echo "   Current RTC time:"
    hwclock -r 2>/dev/null || echo "   ⚠️  hwclock read failed (may need root)"
    
    echo "   System time vs RTC:"
    date
else
    echo "   ⚠️  hwclock command not available"
fi

# Test 5: Check device tree configuration
echo "5. Checking device tree configuration..."
if [ -d /proc/device-tree ]; then
    find /proc/device-tree -name "*rtc*" -o -name "*pcf*" 2>/dev/null | head -3
    find /proc/device-tree -name "*lpi2c3*" 2>/dev/null | head -3
fi

# Test 6: Check interrupt configuration
echo "6. Checking interrupt configuration..."
cat /proc/interrupts | grep -i "rtc\|i2c" | head -3

echo "============================================================"
echo "🏁 RTC Testing Complete"
echo "💡 For full testing, run as root: sudo $0"
