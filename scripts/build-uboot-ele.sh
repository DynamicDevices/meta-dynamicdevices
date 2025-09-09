#!/bin/bash
# Build U-Boot with ELE commands enabled for i.MX93 Jaguar E-Ink
# This script builds only U-Boot to test the new ELE command configuration
# NOTE: ELE debug commands are only included in development builds (DEV_MODE=1)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Building U-Boot with ELE Commands for i.MX93 ==="
echo "Project root: $PROJECT_ROOT"
echo ""

cd "$PROJECT_ROOT"

# Set machine to i.MX93 Jaguar E-Ink
export KAS_MACHINE=imx93-jaguar-eink

# Enable development mode to include ELE debug commands
export DEV_MODE=1

echo "Building U-Boot with enhanced ELE command support..."
echo "Machine: $KAS_MACHINE"
echo "Development Mode: $DEV_MODE (enables ELE debug commands)"
echo ""

# Build only U-Boot to save time
echo "Starting U-Boot build..."
./scripts/kas-shell-base.sh -c "bitbake u-boot-fio -c compile"

echo ""
echo "=== U-Boot Build Complete ==="
echo ""
echo "Next steps:"
echo "1. Build the full image: KAS_MACHINE=imx93-jaguar-eink ./scripts/kas-build-base.sh"
echo "2. Program the board with the new U-Boot"
echo "3. Test ELE commands in U-Boot:"
echo "   - ele info"
echo "   - ele ping"
echo "   - ahab status"
echo "   - fuse read 0 0"
echo "   - mbox list"
echo ""
echo "The new U-Boot should include these ELE commands:"
echo "- ele (EdgeLock Enclave commands)"
echo "- ahab (Advanced High Assurance Boot)"
echo "- fuse (OTP fuse access)"
echo "- mbox (Mailbox communication)"
echo "- fdt (Device tree inspection)"
