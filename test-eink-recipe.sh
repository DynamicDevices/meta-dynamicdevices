#!/bin/bash
# Test script for eink-spectra6 recipe

set -e

echo "=== Testing EL133UF1 E-Ink Driver Recipe ==="
echo "Machine: imx93-jaguar-eink"
echo ""

# Set up environment
export KAS_MACHINE=imx93-jaguar-eink

echo "1. Testing recipe parsing..."
if kas shell kas/lmp-dynamicdevices.yml -c "bitbake-layers show-recipes eink-spectra6" 2>/dev/null; then
    echo "✓ Recipe found and parsed successfully"
else
    echo "✗ Recipe parsing failed"
    exit 1
fi

echo ""
echo "2. Testing recipe dependencies..."
if kas shell kas/lmp-dynamicdevices.yml -c "bitbake -n eink-spectra6" 2>/dev/null; then
    echo "✓ Dependencies resolved successfully"
else
    echo "✗ Dependency resolution failed"
    exit 1
fi

echo ""
echo "3. Testing do_fetch task..."
if kas shell kas/lmp-dynamicdevices.yml -c "bitbake -c fetch eink-spectra6" 2>/dev/null; then
    echo "✓ Source fetch successful"
else
    echo "✗ Source fetch failed"
    exit 1
fi

echo ""
echo "=== All tests passed! ==="
echo ""
echo "To build the complete image with e-ink driver:"
echo "  KAS_MACHINE=imx93-jaguar-eink ./scripts/kas-build-profiling.sh"
echo ""
echo "To build just the e-ink driver:"
echo "  KAS_MACHINE=imx93-jaguar-eink kas shell kas/lmp-dynamicdevices.yml -c 'bitbake eink-spectra6'"
