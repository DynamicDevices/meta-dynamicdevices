#!/bin/bash
# Script to rebuild U-Boot with our fixes for imx93-jaguar-eink

set -e

echo "=== Rebuilding U-Boot for imx93-jaguar-eink with fixes ==="

cd /home/ajlennon/data_drive/dd/meta-dynamicdevices

# Use kas to build U-Boot cleanly
echo "Cleaning and rebuilding U-Boot..."
KAS_MACHINE=imx93-jaguar-eink kas build kas/lmp-dynamicdevices.yml -c "cleanall u-boot-fio" || true
KAS_MACHINE=imx93-jaguar-eink kas build kas/lmp-dynamicdevices.yml:u-boot-fio

echo "=== U-Boot rebuild complete ==="
echo "The new U-Boot binary should include:"
echo "  ✓ Fixed TCPC and PCA953x error messages"
echo "  ✓ Proper board model identification"
echo "  ✓ Fixed environment configuration"
echo "  ✓ Optimized boot settings"
echo ""
echo "New U-Boot files will be in:"
echo "  build/tmp/deploy/images/imx93-jaguar-eink/"
