#!/bin/bash
# Test Build 2134 - Verify LPUART7 Power Management and eink-power-cli

BOARD_IP="${1:-192.168.0.36}"
BOARD_USER="${2:-root}"

echo "🧪 Testing Build 2134 - LPUART7 Power Management & eink-power-cli"
echo "================================================================="
echo "Board: $BOARD_USER@$BOARD_IP"
echo ""

# Test 1: Check if eink-power-cli is installed
echo "1️⃣  Testing eink-power-cli installation..."
if sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "which eink-power-cli" 2>/dev/null; then
    echo "✅ eink-power-cli found at: $(sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "which eink-power-cli" 2>/dev/null)"
    
    # Check symlink
    if sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "which eink-pmu" 2>/dev/null; then
        echo "✅ eink-pmu symlink found at: $(sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "which eink-pmu" 2>/dev/null)"
    else
        echo "⚠️  eink-pmu symlink not found"
    fi
else
    echo "❌ eink-power-cli not found - recipe may have failed"
fi
echo ""

# Test 2: Check LPUART7 power management status
echo "2️⃣  Testing LPUART7 power management..."
LPUART7_CONTROL=$(sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "cat /sys/devices/platform/soc@0/42000000.bus/42690000.serial/power/control 2>/dev/null || echo 'PATH_NOT_FOUND'")

if [ "$LPUART7_CONTROL" = "PATH_NOT_FOUND" ]; then
    echo "⚠️  LPUART7 power control path not found - checking alternative paths..."
    # Try to find the correct path
    LPUART7_PATH=$(sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "find /sys/devices -name '*42690000*' -type d 2>/dev/null | head -1")
    if [ -n "$LPUART7_PATH" ]; then
        echo "🔍 Found LPUART7 at: $LPUART7_PATH"
        LPUART7_CONTROL=$(sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "cat $LPUART7_PATH/power/control 2>/dev/null || echo 'NO_CONTROL'")
    fi
fi

if [ "$LPUART7_CONTROL" = "on" ]; then
    echo "✅ LPUART7 power control: $LPUART7_CONTROL (correctly forced on)"
elif [ "$LPUART7_CONTROL" = "auto" ]; then
    echo "⚠️  LPUART7 power control: $LPUART7_CONTROL (may suspend - check runtime status)"
else
    echo "❌ LPUART7 power control: $LPUART7_CONTROL (unexpected value)"
fi

# Check runtime status
LPUART7_STATUS=$(sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "cat /sys/devices/platform/soc@0/42000000.bus/42690000.serial/power/runtime_status 2>/dev/null || echo 'PATH_NOT_FOUND'")
if [ "$LPUART7_STATUS" = "active" ]; then
    echo "✅ LPUART7 runtime status: $LPUART7_STATUS (good)"
elif [ "$LPUART7_STATUS" = "suspended" ]; then
    echo "❌ LPUART7 runtime status: $LPUART7_STATUS (BAD - communication will fail)"
else
    echo "⚠️  LPUART7 runtime status: $LPUART7_STATUS"
fi
echo ""

# Test 3: Check /dev/ttyLP2 availability
echo "3️⃣  Testing /dev/ttyLP2 device availability..."
if sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "ls -la /dev/ttyLP2" 2>/dev/null; then
    echo "✅ /dev/ttyLP2 device exists"
    TTYLS=$(sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "ls -la /dev/ttyLP2" 2>/dev/null)
    echo "   $TTYLS"
else
    echo "❌ /dev/ttyLP2 device not found"
fi

# Check for mcxc143 symlink
if sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "ls -la /dev/mcxc143" 2>/dev/null; then
    echo "✅ /dev/mcxc143 symlink exists"
    SYMLINKLS=$(sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "ls -la /dev/mcxc143" 2>/dev/null)
    echo "   $SYMLINKLS"
else
    echo "⚠️  /dev/mcxc143 symlink not found (may not be critical)"
fi
echo ""

# Test 4: Check systemd services
echo "4️⃣  Testing systemd services..."
MCXC143_SERVICE=$(sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "systemctl is-active mcxc143-first-boot.service 2>/dev/null || echo 'not-found'")
echo "mcxc143-first-boot.service: $MCXC143_SERVICE"

LPUART7_SERVICE=$(sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "systemctl is-active lpuart7-keep-active.service 2>/dev/null || echo 'not-found'")
echo "lpuart7-keep-active.service: $LPUART7_SERVICE"
echo ""

# Test 5: Basic MCXC143VFM communication test
echo "5️⃣  Testing MCXC143VFM communication..."
if sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "test -c /dev/ttyLP2" 2>/dev/null; then
    echo "Attempting basic communication test..."
    # Configure serial port and test
    COMM_TEST=$(sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "
        stty -F /dev/ttyLP2 115200 cs8 -cstopb -parenb -crtscts raw 2>/dev/null
        echo 'STATUS' > /dev/ttyLP2 2>/dev/null
        timeout 3s cat /dev/ttyLP2 2>/dev/null | head -1
    " 2>/dev/null)
    
    if [ -n "$COMM_TEST" ]; then
        echo "✅ MCXC143VFM communication successful: '$COMM_TEST'"
    else
        echo "⚠️  No response from MCXC143VFM (may need firmware programming)"
    fi
else
    echo "❌ Cannot test communication - /dev/ttyLP2 not available"
fi
echo ""

# Summary
echo "📋 TEST SUMMARY"
echo "==============="
echo "Build 2134 verification complete."
echo ""
echo "🎯 Key Success Criteria:"
echo "- eink-power-cli installed: $([ -n "$(sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "which eink-power-cli" 2>/dev/null)" ] && echo "✅ YES" || echo "❌ NO")"
echo "- LPUART7 active: $([ "$LPUART7_STATUS" = "active" ] && echo "✅ YES" || echo "❌ NO")"
echo "- /dev/ttyLP2 available: $(sshpass -p 'password' ssh -o StrictHostKeyChecking=no $BOARD_USER@$BOARD_IP "test -c /dev/ttyLP2" 2>/dev/null && echo "✅ YES" || echo "❌ NO")"
echo ""
echo "If all criteria are met, Build 2134 successfully resolved the issues from Build 2133!"
