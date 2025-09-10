#!/bin/bash
# SPDX-License-Identifier: GPL-2.0+
# Simple script to toggle E-Ink chip select routing between CS0 and CS1
# Toggles L#R_SEL_DIS (GPIO2_IO16) every 250ms

set -euo pipefail

# Configuration
TARGET_IP="${TARGET_IP:-62.3.79.162}"
TARGET_USER="${TARGET_USER:-fio}"

# GPIO mapping for i.MX93
LR_SEL_GPIO=528   # GPIO2_IO16 (512 + 16) - L#R_SEL_DIS

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Create the toggle script to run on target
create_target_script() {
    log_info "Creating toggle script on target board..."
    
    ssh "${TARGET_USER}@${TARGET_IP}" "cat > /tmp/cs_toggle.sh << 'EOF'
#!/bin/bash
# CS Toggle script - runs on target board

LR_SEL_GPIO=528
DELAY=0.25  # 250ms

echo \"Starting E-Ink CS toggle test...\"
echo \"L/R Select GPIO: \$LR_SEL_GPIO (GPIO2_IO16 - CORRECTED)\"
echo \"Toggle interval: \${DELAY}s (250ms)\"
echo \"Press Ctrl+C to stop\"
echo \"\"

# Export GPIO if not already exported
if [ ! -d \"/sys/class/gpio/gpio\$LR_SEL_GPIO\" ]; then
    echo \$LR_SEL_GPIO > /sys/class/gpio/export 2>/dev/null || {
        echo \"Error: Failed to export GPIO \$LR_SEL_GPIO\"
        exit 1
    }
fi

# Set GPIO direction to output
echo out > /sys/class/gpio/gpio\$LR_SEL_GPIO/direction || {
    echo \"Error: Failed to set GPIO direction\"
    exit 1
}

echo \"GPIO \$LR_SEL_GPIO exported and configured as output\"
echo \"\"

# Cleanup function
cleanup() {
    echo \"\"
    echo \"Cleaning up...\"
    if [ -d \"/sys/class/gpio/gpio\$LR_SEL_GPIO\" ]; then
        echo \$LR_SEL_GPIO > /sys/class/gpio/unexport 2>/dev/null || true
    fi
    echo \"GPIO unexported\"
    exit 0
}

# Set up cleanup trap
trap cleanup INT TERM

# Toggle loop
counter=0
while true; do
    # Set to CS0 (Left controller) - L#R_SEL_DIS = LOW
    echo 0 > /sys/class/gpio/gpio\$LR_SEL_GPIO/value
    counter=\$((counter + 1))
    echo \"[\$counter] CS0 (Left controller)  - L#R_SEL_DIS = LOW\"
    sleep \$DELAY
    
    # Set to CS1 (Right controller) - L#R_SEL_DIS = HIGH  
    echo 1 > /sys/class/gpio/gpio\$LR_SEL_GPIO/value
    echo \"[\$counter] CS1 (Right controller) - L#R_SEL_DIS = HIGH\"
    sleep \$DELAY
done
EOF"

    # Make the script executable
    ssh "${TARGET_USER}@${TARGET_IP}" "chmod +x /tmp/cs_toggle.sh"
    
    log_success "Toggle script created on target board"
}

# Run the toggle script on target
run_toggle_script() {
    log_info "Starting CS toggle on target board ${TARGET_IP}..."
    log_info "This will toggle between CS0 (left) and CS1 (right) every 250ms"
    log_info "Press Ctrl+C to stop the test"
    echo ""
    
    # Run the script with sudo on the target
    ssh "${TARGET_USER}@${TARGET_IP}" "sudo /tmp/cs_toggle.sh"
}

# Main execution
main() {
    log_info "E-Ink Chip Select Toggle Test"
    log_info "Target: ${TARGET_USER}@${TARGET_IP}"
    log_info "GPIO: ${LR_SEL_GPIO} (GPIO2_IO16 - L#R_SEL_DIS)"
    echo ""
    
    # Check if target is reachable
    if ! ping -c 1 -W 5 "$TARGET_IP" >/dev/null 2>&1; then
        echo "Error: Target $TARGET_IP is not reachable"
        exit 1
    fi
    
    if ! ssh -o ConnectTimeout=5 "${TARGET_USER}@${TARGET_IP}" "echo 'Connection test'" >/dev/null 2>&1; then
        echo "Error: SSH connection to ${TARGET_USER}@${TARGET_IP} failed"
        exit 1
    fi
    
    create_target_script
    run_toggle_script
}

# Parse command line arguments
case "${1:-run}" in
    "run"|"")
        main
        ;;
    "create")
        create_target_script
        ;;
    *)
        echo "Usage: $0 [run|create]"
        echo ""
        echo "Commands:"
        echo "  run     - Create and run the toggle script (default)"
        echo "  create  - Only create the script on target, don't run it"
        echo ""
        echo "Environment variables:"
        echo "  TARGET_IP   - Target board IP address (default: 62.3.79.162)"
        echo "  TARGET_USER - Target board username (default: fio)"
        exit 1
        ;;
esac
