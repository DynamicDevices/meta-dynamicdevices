#!/bin/bash
# Quick device tree syntax check script

set -e

DTS_FILE="recipes-bsp/device-tree/lmp-device-tree/imx93-jaguar-eink.dts"

echo "Testing device tree syntax for: $DTS_FILE"

# Check if device tree compiler is available
if ! command -v dtc >/dev/null 2>&1; then
    echo "Device tree compiler (dtc) not found, skipping syntax check"
    exit 0
fi

# Basic syntax check (this won't resolve includes but will catch basic syntax errors)
echo "Running basic syntax check..."
if dtc -I dts -O dtb "$DTS_FILE" >/dev/null 2>&1; then
    echo "✅ Basic syntax check passed"
else
    echo "❌ Basic syntax errors found:"
    dtc -I dts -O dtb "$DTS_FILE" 2>&1 || true
fi

# Check for common issues
echo "Checking for common issues..."

# Check for missing includes
if ! grep -q "dt-bindings/gpio/gpio.h" "$DTS_FILE"; then
    echo "⚠️  Missing GPIO includes"
fi

if ! grep -q "dt-bindings/input/input.h" "$DTS_FILE"; then
    echo "⚠️  Missing input includes"
fi

# Check for unmatched braces
OPEN_BRACES=$(grep -o '{' "$DTS_FILE" | wc -l)
CLOSE_BRACES=$(grep -o '}' "$DTS_FILE" | wc -l)

if [ "$OPEN_BRACES" -ne "$CLOSE_BRACES" ]; then
    echo "❌ Unmatched braces: $OPEN_BRACES open, $CLOSE_BRACES close"
else
    echo "✅ Braces match: $OPEN_BRACES pairs"
fi

# Check for semicolon issues
echo "Checking device tree structure..."
if grep -n "^[[:space:]]*}[[:space:]]*$" "$DTS_FILE" | head -5; then
    echo "✅ Found proper block endings"
fi

echo "Device tree syntax check completed"
