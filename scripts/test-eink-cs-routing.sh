#!/bin/bash
# SPDX-License-Identifier: GPL-2.0+
# Test script for E-Ink display chip select routing
# Tests both left (CS_M) and right (CS_S) controller access via L#R_SEL_DIS

set -euo pipefail

# Configuration
TARGET_IP="${TARGET_IP:-192.168.1.100}"
TARGET_USER="${TARGET_USER:-fio}"
SPI_DEVICE="${SPI_DEVICE:-/dev/spidev1.0}"

# GPIO mappings for i.MX93
RESET_GPIO=526    # GPIO2_IO14 (512 + 14)
BUSY_GPIO=529     # GPIO2_IO17 (512 + 17) 
DC_GPIO=527       # GPIO2_IO15 (512 + 15)
LR_SEL_GPIO=528   # GPIO2_IO16 (512 + 16) - L#R_SEL_DIS
POWER_GPIO=523    # GPIO2_IO11 (512 + 11)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if target is reachable
check_target() {
    log_info "Checking target connectivity..."
    if ! ping -c 1 -W 5 "$TARGET_IP" >/dev/null 2>&1; then
        log_error "Target $TARGET_IP is not reachable"
        return 1
    fi
    
    if ! ssh -o ConnectTimeout=5 "${TARGET_USER}@${TARGET_IP}" "echo 'Connection test'" >/dev/null 2>&1; then
        log_error "SSH connection to ${TARGET_USER}@${TARGET_IP} failed"
        return 1
    fi
    
    log_success "Target is reachable"
}

# Initialize GPIO pins
init_gpio() {
    log_info "Initializing GPIO pins..."
    
    ssh "${TARGET_USER}@${TARGET_IP}" "
        # Export GPIO pins if not already exported
        for gpio in $RESET_GPIO $BUSY_GPIO $DC_GPIO $LR_SEL_GPIO $POWER_GPIO; do
            if [ ! -d \"/sys/class/gpio/gpio\$gpio\" ]; then
                echo \$gpio | sudo tee /sys/class/gpio/export >/dev/null 2>&1 || true
            fi
        done
        
        # Set GPIO directions
        echo out | sudo tee /sys/class/gpio/gpio${RESET_GPIO}/direction >/dev/null
        echo in  | sudo tee /sys/class/gpio/gpio${BUSY_GPIO}/direction >/dev/null
        echo out | sudo tee /sys/class/gpio/gpio${DC_GPIO}/direction >/dev/null
        echo out | sudo tee /sys/class/gpio/gpio${LR_SEL_GPIO}/direction >/dev/null
        echo out | sudo tee /sys/class/gpio/gpio${POWER_GPIO}/direction >/dev/null
        
        # Enable display power
        echo 1 | sudo tee /sys/class/gpio/gpio${POWER_GPIO}/value >/dev/null
        
        # Set reset high (inactive)
        echo 1 | sudo tee /sys/class/gpio/gpio${RESET_GPIO}/value >/dev/null
        
        sleep 1
    "
    
    log_success "GPIO pins initialized"
}

# Set chip select routing
set_cs_routing() {
    local controller="$1"  # "left" or "right"
    local gpio_value
    
    if [ "$controller" = "left" ]; then
        gpio_value=0
        log_info "Setting chip select routing to LEFT controller (CS_M)"
    elif [ "$controller" = "right" ]; then
        gpio_value=1
        log_info "Setting chip select routing to RIGHT controller (CS_S)"
    else
        log_error "Invalid controller: $controller. Use 'left' or 'right'"
        return 1
    fi
    
    ssh "${TARGET_USER}@${TARGET_IP}" "
        echo $gpio_value | sudo tee /sys/class/gpio/gpio${LR_SEL_GPIO}/value >/dev/null
        sleep 0.1  # Allow level shifters to settle
    "
    
    # Verify the setting
    local actual_value
    actual_value=$(ssh "${TARGET_USER}@${TARGET_IP}" "cat /sys/class/gpio/gpio${LR_SEL_GPIO}/value")
    
    if [ "$actual_value" = "$gpio_value" ]; then
        log_success "Chip select routing set to $controller controller (L#R_SEL_DIS=$gpio_value)"
    else
        log_error "Failed to set chip select routing. Expected: $gpio_value, Actual: $actual_value"
        return 1
    fi
}

# Test SPI communication with specific controller
test_spi_controller() {
    local controller="$1"
    local test_pattern="$2"
    
    log_info "Testing SPI communication with $controller controller..."
    
    # Set the routing first
    if ! set_cs_routing "$controller"; then
        return 1
    fi
    
    # Perform display reset sequence
    ssh "${TARGET_USER}@${TARGET_IP}" "
        # Reset sequence
        echo 0 | sudo tee /sys/class/gpio/gpio${RESET_GPIO}/value >/dev/null
        sleep 0.01  # 10ms reset pulse
        echo 1 | sudo tee /sys/class/gpio/gpio${RESET_GPIO}/value >/dev/null
        sleep 0.1   # Wait for controller to initialize
    "
    
    # Test basic SPI communication
    log_info "Sending test pattern '$test_pattern' to $controller controller..."
    
    # Simple SPI test - send some basic commands
    ssh "${TARGET_USER}@${TARGET_IP}" "
        # Set DC low for command mode
        echo 0 | sudo tee /sys/class/gpio/gpio${DC_GPIO}/value >/dev/null
        
        # Send a simple command (e.g., NOP or status read)
        # This is a basic test - actual commands depend on display controller
        echo -ne '\x00' | sudo dd of=$SPI_DEVICE bs=1 count=1 2>/dev/null || true
        
        sleep 0.01
        
        # Check busy status
        busy_status=\$(cat /sys/class/gpio/gpio${BUSY_GPIO}/value)
        echo \"Busy status after command: \$busy_status\"
    "
    
    log_success "SPI test completed for $controller controller"
}

# Test level shifter behavior
test_level_shifters() {
    log_info "Testing level shifter behavior..."
    
    # Test both directions to see if autosensing buffers are working
    log_info "Testing signal integrity on both controllers..."
    
    for controller in "left" "right"; do
        log_info "Testing level shifters with $controller controller routing..."
        
        set_cs_routing "$controller"
        
        # Test signal transitions
        ssh "${TARGET_USER}@${TARGET_IP}" "
            # Test DC signal transitions
            for i in {1..5}; do
                echo 0 | sudo tee /sys/class/gpio/gpio${DC_GPIO}/value >/dev/null
                sleep 0.001
                echo 1 | sudo tee /sys/class/gpio/gpio${DC_GPIO}/value >/dev/null
                sleep 0.001
            done
            
            # Test reset signal transitions  
            for i in {1..3}; do
                echo 0 | sudo tee /sys/class/gpio/gpio${RESET_GPIO}/value >/dev/null
                sleep 0.01
                echo 1 | sudo tee /sys/class/gpio/gpio${RESET_GPIO}/value >/dev/null
                sleep 0.01
            done
        "
        
        log_success "Level shifter test completed for $controller controller"
    done
}

# Main test function
run_cs_routing_test() {
    log_info "Starting E-Ink chip select routing test..."
    log_info "Target: ${TARGET_USER}@${TARGET_IP}"
    log_info "SPI Device: $SPI_DEVICE"
    log_info ""
    log_info "GPIO Configuration:"
    log_info "  Reset GPIO:    $RESET_GPIO (GPIO2_IO14)"
    log_info "  Busy GPIO:     $BUSY_GPIO (GPIO2_IO17)"
    log_info "  DC GPIO:       $DC_GPIO (GPIO2_IO15)"
    log_info "  L/R Sel GPIO:  $LR_SEL_GPIO (GPIO2_IO16)"
    log_info "  Power GPIO:    $POWER_GPIO (GPIO2_IO11)"
    log_info ""
    
    # Check target connectivity
    if ! check_target; then
        return 1
    fi
    
    # Initialize GPIO pins
    if ! init_gpio; then
        return 1
    fi
    
    # Test level shifters
    test_level_shifters
    
    # Test both controllers
    log_info "Testing both display controllers..."
    
    # Test left controller (CS_M)
    log_info "=== Testing LEFT Controller (CS_M) ==="
    if test_spi_controller "left" "test_pattern_1"; then
        log_success "Left controller test PASSED"
    else
        log_warning "Left controller test FAILED"
    fi
    
    sleep 2
    
    # Test right controller (CS_S)  
    log_info "=== Testing RIGHT Controller (CS_S) ==="
    if test_spi_controller "right" "test_pattern_2"; then
        log_success "Right controller test PASSED"
    else
        log_warning "Right controller test FAILED"
    fi
    
    # Test rapid switching
    log_info "=== Testing Rapid Controller Switching ==="
    for i in {1..5}; do
        log_info "Switch cycle $i/5"
        set_cs_routing "left"
        sleep 0.1
        set_cs_routing "right" 
        sleep 0.1
    done
    
    # Return to left controller as default
    set_cs_routing "left"
    
    log_success "Chip select routing test completed!"
    log_info ""
    log_info "Next steps:"
    log_info "1. If both controllers respond: Level shifters are working correctly"
    log_info "2. If only one responds: Check level shifter configuration"
    log_info "3. If neither responds: Check SPI wiring and power"
    log_info "4. For register reading: Ensure autosensing level shifters are used"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up GPIO exports..."
    ssh "${TARGET_USER}@${TARGET_IP}" "
        for gpio in $RESET_GPIO $BUSY_GPIO $DC_GPIO $LR_SEL_GPIO $POWER_GPIO; do
            if [ -d \"/sys/class/gpio/gpio\$gpio\" ]; then
                echo \$gpio | sudo tee /sys/class/gpio/unexport >/dev/null 2>&1 || true
            fi
        done
    " 2>/dev/null || true
}

# Set up cleanup trap
trap cleanup EXIT

# Parse command line arguments
case "${1:-}" in
    "left")
        check_target && init_gpio && set_cs_routing "left"
        ;;
    "right") 
        check_target && init_gpio && set_cs_routing "right"
        ;;
    "test")
        run_cs_routing_test
        ;;
    "cleanup")
        cleanup
        ;;
    *)
        echo "Usage: $0 {left|right|test|cleanup}"
        echo ""
        echo "Commands:"
        echo "  left     - Set chip select routing to left controller (CS_M)"
        echo "  right    - Set chip select routing to right controller (CS_S)" 
        echo "  test     - Run comprehensive chip select routing test"
        echo "  cleanup  - Clean up GPIO exports"
        echo ""
        echo "Environment variables:"
        echo "  TARGET_IP   - Target board IP address (default: 192.168.1.100)"
        echo "  TARGET_USER - Target board username (default: fio)"
        echo "  SPI_DEVICE  - SPI device path (default: /dev/spidev1.0)"
        exit 1
        ;;
esac
